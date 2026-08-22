# scripts/train_phase_model.py

import csv
import random
import sys
from pathlib import Path
from collections import Counter, defaultdict

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


# ============================================================
# Make project root importable
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT))


from ai_rep_counter.features import get_feature_size
from ai_rep_counter.phase_model import PhaseMLP


# ============================================================
# Config
# ============================================================

DATA_PATH = PROJECT_ROOT / "data" / "rep_counter" / "phase_dataset.csv"
MODEL_PATH = PROJECT_ROOT / "ai_rep_counter" / "models" / "phase_model.pt"

SEED = 42
VAL_RATIO = 0.2

BATCH_SIZE = 64
EPOCHS = 80
LEARNING_RATE = 1e-3
WEIGHT_DECAY = 1e-4
PATIENCE = 12


LABEL_TO_ID = {
    "other": 0,
    "squat_up": 1,
    "squat_down": 2,
    "pushup_up": 3,
    "pushup_down": 4,
}

ID_TO_LABEL = {
    0: "other",
    1: "squat_up",
    2: "squat_down",
    3: "pushup_up",
    4: "pushup_down",
}


# ============================================================
# Utilities
# ============================================================

def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)

    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def load_dataset():
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Dataset not found: {DATA_PATH}")

    X = []
    y = []

    expected_feature_size = get_feature_size()

    with open(DATA_PATH, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader, None)

        if header is None:
            raise ValueError("CSV file is empty.")

        for row_idx, row in enumerate(reader, start=2):
            if not row:
                continue

            label = row[0]

            if label not in LABEL_TO_ID:
                print(f"[WARN] Unknown label at row {row_idx}: {label}")
                continue

            features = row[1:]

            if len(features) != expected_feature_size:
                print(
                    f"[WARN] Bad feature size at row {row_idx}: "
                    f"got {len(features)}, expected {expected_feature_size}"
                )
                continue

            try:
                features = [float(v) for v in features]
            except ValueError:
                print(f"[WARN] Could not parse features at row {row_idx}")
                continue

            X.append(features)
            y.append(LABEL_TO_ID[label])

    if not X:
        raise ValueError("No valid samples found in dataset.")

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int64)

    return X, y


def print_class_distribution(y, title):
    counter = Counter(y)

    print(f"\n===== {title} =====")
    for class_id in sorted(ID_TO_LABEL.keys()):
        label = ID_TO_LABEL[class_id]
        count = counter.get(class_id, 0)
        print(f"{label:15s}: {count}")
    print("====================\n")


def stratified_split(X, y, val_ratio=0.2):
    """
    Split dataset while keeping class distribution balanced.
    """

    class_indices = defaultdict(list)

    for idx, label_id in enumerate(y):
        class_indices[label_id].append(idx)

    train_indices = []
    val_indices = []

    for label_id, indices in class_indices.items():
        random.shuffle(indices)

        val_size = max(1, int(len(indices) * val_ratio))

        val_indices.extend(indices[:val_size])
        train_indices.extend(indices[val_size:])

    random.shuffle(train_indices)
    random.shuffle(val_indices)

    X_train = X[train_indices]
    y_train = y[train_indices]

    X_val = X[val_indices]
    y_val = y[val_indices]

    return X_train, y_train, X_val, y_val


def compute_class_weights(y_train, num_classes):
    """
    Balanced class weights for CrossEntropyLoss.
    Useful if one class has more samples than others.
    """

    counter = Counter(y_train)
    total = len(y_train)

    weights = []

    for class_id in range(num_classes):
        class_count = counter.get(class_id, 1)
        weight = total / (num_classes * class_count)
        weights.append(weight)

    return torch.tensor(weights, dtype=torch.float32)


def evaluate(model, loader, criterion, device):
    model.eval()

    total_loss = 0.0
    total_correct = 0
    total_samples = 0

    class_correct = Counter()
    class_total = Counter()

    all_preds = []
    all_labels = []

    with torch.no_grad():
        for xb, yb in loader:
            xb = xb.to(device)
            yb = yb.to(device)

            logits = model(xb)
            loss = criterion(logits, yb)

            preds = logits.argmax(dim=1)

            total_loss += loss.item() * yb.size(0)
            total_correct += (preds == yb).sum().item()
            total_samples += yb.size(0)

            for pred, label in zip(preds.cpu().numpy(), yb.cpu().numpy()):
                class_total[int(label)] += 1

                if int(pred) == int(label):
                    class_correct[int(label)] += 1

                all_preds.append(int(pred))
                all_labels.append(int(label))

    avg_loss = total_loss / max(total_samples, 1)
    accuracy = total_correct / max(total_samples, 1)

    per_class_acc = {}

    for class_id in range(len(ID_TO_LABEL)):
        total = class_total.get(class_id, 0)
        correct = class_correct.get(class_id, 0)

        if total == 0:
            per_class_acc[class_id] = 0.0
        else:
            per_class_acc[class_id] = correct / total

    return avg_loss, accuracy, per_class_acc, all_preds, all_labels


def print_per_class_accuracy(per_class_acc):
    print("Per-class accuracy:")

    for class_id, acc in per_class_acc.items():
        label = ID_TO_LABEL[class_id]
        print(f"  {label:15s}: {acc:.4f}")


# ============================================================
# Main training
# ============================================================

def main():
    set_seed(SEED)

    print(f"Dataset path: {DATA_PATH}")
    print(f"Model output: {MODEL_PATH}")

    X, y = load_dataset()

    print(f"\nLoaded dataset:")
    print(f"X shape: {X.shape}")
    print(f"y shape: {y.shape}")

    if X.shape[1] != get_feature_size():
        raise ValueError(
            f"Feature size mismatch: X has {X.shape[1]}, "
            f"expected {get_feature_size()}"
        )

    print_class_distribution(y, "Full dataset distribution")

    if len(X) < 500:
        print("[WARN] Dataset is small. You can still train, but accuracy may be unstable.")

    X_train, y_train, X_val, y_val = stratified_split(
        X,
        y,
        val_ratio=VAL_RATIO,
    )

    print(f"Train size: {len(X_train)}")
    print(f"Val size:   {len(X_val)}")

    print_class_distribution(y_train, "Train distribution")
    print_class_distribution(y_val, "Validation distribution")

    train_dataset = TensorDataset(
        torch.tensor(X_train, dtype=torch.float32),
        torch.tensor(y_train, dtype=torch.long),
    )

    val_dataset = TensorDataset(
        torch.tensor(X_val, dtype=torch.float32),
        torch.tensor(y_val, dtype=torch.long),
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=BATCH_SIZE,
        shuffle=True,
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=BATCH_SIZE,
        shuffle=False,
    )

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"\nUsing device: {device}")

    model = PhaseMLP(
        input_size=get_feature_size(),
        num_classes=len(LABEL_TO_ID),
    ).to(device)

    class_weights = compute_class_weights(
        y_train,
        num_classes=len(LABEL_TO_ID),
    ).to(device)

    print(f"Class weights: {class_weights.detach().cpu().numpy()}")

    criterion = nn.CrossEntropyLoss(weight=class_weights)

    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=LEARNING_RATE,
        weight_decay=WEIGHT_DECAY,
    )

    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer,
        mode="max",
        factor=0.5,
        patience=4,
    )

    best_val_acc = 0.0
    best_epoch = 0
    no_improve_count = 0

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)

    print("\n===== Training started =====")

    for epoch in range(1, EPOCHS + 1):
        model.train()

        train_loss = 0.0
        train_correct = 0
        train_total = 0

        for xb, yb in train_loader:
            xb = xb.to(device)
            yb = yb.to(device)

            optimizer.zero_grad()

            logits = model(xb)
            loss = criterion(logits, yb)

            loss.backward()
            optimizer.step()

            preds = logits.argmax(dim=1)

            train_loss += loss.item() * yb.size(0)
            train_correct += (preds == yb).sum().item()
            train_total += yb.size(0)

        train_loss /= max(train_total, 1)
        train_acc = train_correct / max(train_total, 1)

        val_loss, val_acc, per_class_acc, _, _ = evaluate(
            model,
            val_loader,
            criterion,
            device,
        )

        scheduler.step(val_acc)

        current_lr = optimizer.param_groups[0]["lr"]

        print(
            f"Epoch {epoch:03d}/{EPOCHS} | "
            f"train_loss={train_loss:.4f} | "
            f"train_acc={train_acc:.4f} | "
            f"val_loss={val_loss:.4f} | "
            f"val_acc={val_acc:.4f} | "
            f"lr={current_lr:.6f}"
        )

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            best_epoch = epoch
            no_improve_count = 0

            checkpoint = {
                "model_state": model.state_dict(),
                "input_size": get_feature_size(),
                "num_classes": len(LABEL_TO_ID),
                "label_to_id": LABEL_TO_ID,
                "id_to_label": ID_TO_LABEL,
                "best_val_acc": best_val_acc,
                "best_epoch": best_epoch,
                "selected_keypoints": None,
            }

            torch.save(checkpoint, MODEL_PATH)

            print(f"Saved best model: {MODEL_PATH}")
            print_per_class_accuracy(per_class_acc)

        else:
            no_improve_count += 1

        if no_improve_count >= PATIENCE:
            print(
                f"\nEarly stopping at epoch {epoch}. "
                f"No improvement for {PATIENCE} epochs."
            )
            break

    print("\n===== Training finished =====")
    print(f"Best val acc: {best_val_acc:.4f}")
    print(f"Best epoch:   {best_epoch}")
    print(f"Saved model:  {MODEL_PATH}")

    if best_val_acc < 0.85:
        print("\n[NOTE] Accuracy is still low.")
        print("You may need more data, especially for weak classes.")
    elif best_val_acc < 0.92:
        print("\n[NOTE] Accuracy is usable for first demo.")
        print("Test in main.py and collect more data if rep count is unstable.")
    else:
        print("\n[GOOD] Accuracy looks good. Now test with main.py.")


if __name__ == "__main__":
    main()
