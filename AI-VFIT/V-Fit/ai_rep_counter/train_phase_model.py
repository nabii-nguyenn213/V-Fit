# scripts/train_phase_model.py

import csv
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT))


from ai_rep_counter.features import get_feature_size
from ai_rep_counter.phase_model import PhaseMLP


DATA_PATH = PROJECT_ROOT / "data" / "rep_counter" / "phase_dataset.csv"
MODEL_PATH = PROJECT_ROOT / "ai_rep_counter" / "models" / "phase_model.pt"


LABEL_TO_ID = {
    "other": 0,
    "squat_up": 1,
    "squat_down": 2,
    "pushup_up": 3,
    "pushup_down": 4,
}

ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def load_dataset():
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Dataset not found: {DATA_PATH}")

    X = []
    y = []

    with open(DATA_PATH, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)

        for row in reader:
            if not row:
                continue

            label = row[0]

            if label not in LABEL_TO_ID:
                continue

            features = [float(v) for v in row[1:]]

            if len(features) != get_feature_size():
                continue

            X.append(features)
            y.append(LABEL_TO_ID[label])

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int64)

    return X, y


def split_dataset(X, y, val_ratio=0.2):
    indices = np.arange(len(X))
    np.random.shuffle(indices)

    val_size = int(len(indices) * val_ratio)

    val_idx = indices[:val_size]
    train_idx = indices[val_size:]

    return X[train_idx], y[train_idx], X[val_idx], y[val_idx]


def evaluate(model, loader, device):
    model.eval()

    correct = 0
    total = 0
    loss_total = 0.0

    criterion = nn.CrossEntropyLoss()

    with torch.no_grad():
        for xb, yb in loader:
            xb = xb.to(device)
            yb = yb.to(device)

            logits = model(xb)
            loss = criterion(logits, yb)

            pred = logits.argmax(dim=1)

            correct += (pred == yb).sum().item()
            total += yb.size(0)
            loss_total += loss.item() * yb.size(0)

    acc = correct / max(total, 1)
    avg_loss = loss_total / max(total, 1)

    return avg_loss, acc


def main():
    X, y = load_dataset()

    print(f"Loaded dataset: X={X.shape}, y={y.shape}")

    if len(X) < 100:
        print("Dataset is too small. Collect more samples first.")
        return

    X_train, y_train, X_val, y_val = split_dataset(X, y)

    train_ds = TensorDataset(
        torch.tensor(X_train, dtype=torch.float32),
        torch.tensor(y_train, dtype=torch.long),
    )

    val_ds = TensorDataset(
        torch.tensor(X_val, dtype=torch.float32),
        torch.tensor(y_val, dtype=torch.long),
    )

    train_loader = DataLoader(
        train_ds,
        batch_size=64,
        shuffle=True,
    )

    val_loader = DataLoader(
        val_ds,
        batch_size=128,
        shuffle=False,
    )

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")

    model = PhaseMLP(
        input_size=get_feature_size(),
        num_classes=len(LABEL_TO_ID),
    ).to(device)

    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=1e-3,
        weight_decay=1e-4,
    )

    criterion = nn.CrossEntropyLoss()

    best_val_acc = 0.0
    epochs = 40

    for epoch in range(1, epochs + 1):
        model.train()

        train_loss = 0.0

        for xb, yb in train_loader:
            xb = xb.to(device)
            yb = yb.to(device)

            optimizer.zero_grad()

            logits = model(xb)
            loss = criterion(logits, yb)

            loss.backward()
            optimizer.step()

            train_loss += loss.item() * yb.size(0)

        train_loss /= len(train_ds)

        val_loss, val_acc = evaluate(model, val_loader, device)

        print(
            f"Epoch {epoch:03d} | "
            f"train_loss={train_loss:.4f} | "
            f"val_loss={val_loss:.4f} | "
            f"val_acc={val_acc:.4f}"
        )

        if val_acc > best_val_acc:
            best_val_acc = val_acc

            MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)

            torch.save(
                {
                    "model_state": model.state_dict(),
                    "input_size": get_feature_size(),
                    "num_classes": len(LABEL_TO_ID),
                    "label_to_id": LABEL_TO_ID,
                    "id_to_label": ID_TO_LABEL,
                    "best_val_acc": best_val_acc,
                },
                MODEL_PATH,
            )

            print(f"Saved best model to: {MODEL_PATH}")

    print(f"Best val acc: {best_val_acc:.4f}")


if __name__ == "__main__":
    main()
