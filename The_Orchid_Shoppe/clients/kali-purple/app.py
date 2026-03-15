from flask import Flask, render_template, request
import hashlib
import json
import os
from datetime import datetime

app = Flask(__name__)

# --------------------------------------------
# Lockheed Martin Kill Chain - Flag Portal
# Author: Jason
# Purpose:
# Simple local training portal for Flag 1-5
# --------------------------------------------

FLAGS = {
    "flag1": "flag{domain_users_42}",
    "flag2": "flag{upload_complete}",
    "flag3": "flag{ps_exec_ok}",
    "flag4": "flag{fileshare_open}",
    "flag5": "flag{objective_complete}"
}

LOG_FILE = "/opt/killchain-flags/submissions.log"
SCORE_FILE = "/opt/killchain-flags/score.json"


def init_score():
    if not os.path.exists(SCORE_FILE):
        with open(SCORE_FILE, "w") as f:
            json.dump({
                "flag1": False,
                "flag2": False,
                "flag3": False,
                "flag4": False,
                "flag5": False
            }, f, indent=4)


def load_score():
    with open(SCORE_FILE, "r") as f:
        return json.load(f)


def save_score(score):
    with open(SCORE_FILE, "w") as f:
        json.dump(score, f, indent=4)


def write_log(flag_name, submitted_value, status):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    hashed = hashlib.sha256(submitted_value.encode()).hexdigest()
    line = f"[{ts}] {flag_name} | {status} | sha256={hashed}\n"
    with open(LOG_FILE, "a") as f:
        f.write(line)


@app.route("/", methods=["GET", "POST"])
def index():
    init_score()
    message = ""
    score = load_score()

    if request.method == "POST":
        flag_name = request.form.get("flag_name", "").strip()
        submitted_flag = request.form.get("submitted_flag", "").strip()

        if flag_name in FLAGS:
            if submitted_flag == FLAGS[flag_name]:
                score[flag_name] = True
                save_score(score)
                write_log(flag_name, submitted_flag, "CORRECT")
                message = f"{flag_name.upper()} correct."
            else:
                write_log(flag_name, submitted_flag, "INCORRECT")
                message = f"{flag_name.upper()} incorrect. Try again."
        else:
            message = "Invalid flag selection."

    total_correct = sum(1 for v in score.values() if v)
    return render_template("index.html", message=message, score=score, total_correct=total_correct)


@app.route("/reset", methods=["POST"])
def reset():
    reset_score = {
        "flag1": False,
        "flag2": False,
        "flag3": False,
        "flag4": False,
        "flag5": False
    }
    save_score(reset_score)
    return render_template("index.html", message="Score reset complete.", score=reset_score, total_correct=0)


if __name__ == "__main__":
    init_score()
    app.run(host="0.0.0.0", port=5000, debug=False)
