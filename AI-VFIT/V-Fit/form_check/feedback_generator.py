FEEDBACK_DATABASE = {
    "no_pose": {
        "warning": "Không phát hiện được cơ thể.",
        "correction": "Hãy đứng hoặc nằm sao cho toàn thân nằm trong khung hình camera.",
        "severity": "high",
    },

    "good_form": {
        "warning": "Form tốt.",
        "correction": "Tiếp tục giữ nhịp độ và kiểm soát động tác.",
        "severity": "low",
    },

    # Squat
    "squat_not_deep_enough": {
        "warning": "Squat chưa đủ sâu.",
        "correction": "Hạ người xuống đến khi đùi gần song song với sàn hoặc thấp hơn một chút.",
        "severity": "medium",
    },
    "squat_knee_inward": {
        "warning": "Gối đang chụm vào trong.",
        "correction": "Đẩy gối ra ngoài và giữ gối đi cùng hướng với mũi chân.",
        "severity": "high",
    },
    "squat_back_leaning": {
        "warning": "Thân người đang nghiêng quá nhiều.",
        "correction": "Mở ngực, gồng core và giữ lưng neutral hơn.",
        "severity": "medium",
    },
    "squat_leg_imbalance": {
        "warning": "Hai chân di chuyển không đều.",
        "correction": "Dồn lực đều hai chân và đẩy lên bằng midfoot.",
        "severity": "medium",
    },

    # Push-up
    "pushup_not_low_enough": {
        "warning": "Push-up chưa xuống đủ sâu.",
        "correction": "Hạ ngực thấp hơn, giữ kiểm soát và không thả người quá nhanh.",
        "severity": "medium",
    },
    "pushup_hip_sag": {
        "warning": "Hông đang võng xuống.",
        "correction": "Gồng bụng và giữ vai, hông, gót chân trên một đường thẳng.",
        "severity": "high",
    },
    "pushup_hip_too_high": {
        "warning": "Mông đang nâng quá cao.",
        "correction": "Hạ hông xuống một chút để thân người thẳng hơn.",
        "severity": "medium",
    },
    "pushup_elbow_flare": {
        "warning": "Khuỷu tay có thể đang mở quá rộng.",
        "correction": "Giữ khuỷu ở góc khoảng 45–70 độ so với thân người.",
        "severity": "medium",
    },
}


def generate_feedback(errors):
    if not errors:
        return [
            {
                "code": "good_form",
                **FEEDBACK_DATABASE["good_form"],
            }
        ]

    feedback = []

    for error in errors:
        code = error.get("code") if isinstance(error, dict) else str(error)

        item = FEEDBACK_DATABASE.get(
            code,
            {
                "warning": code,
                "correction": "Kiểm tra lại form tập.",
                "severity": "medium",
            },
        )

        severity = error.get("severity", item["severity"]) if isinstance(error, dict) else item["severity"]

        feedback.append(
            {
                "code": code,
                "warning": item["warning"],
                "correction": item["correction"],
                "severity": severity,
            }
        )

    return feedback
