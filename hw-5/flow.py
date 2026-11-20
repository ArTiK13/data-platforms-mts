import subprocess
from pathlib import Path

from prefect import flow


@flow(name="hw5-events")
def events_flow():
    subprocess.run(["bash", str(Path.home() / "hw4-spark/run.sh")], check=True)
    subprocess.run(["bash", str(Path.home() / "hw4-spark/check.sh")], check=True)


if __name__ == "__main__":
    events_flow()
