"""GUI integration checks; run under a private session bus and Xvfb."""

import os
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def wait_for_log(process, log, messages):
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        text = log.read_text()
        if all(message in text for message in messages):
            return
        if process.poll() is not None:
            raise AssertionError(f"Application exited early:\n{text}")
        time.sleep(0.05)
    raise AssertionError(f"File arguments were not applied: {messages}\n{log.read_text()}")


def check_opening(binary, start_with_files):
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        files = [root / name for name in ("first document.pdf", "Überblick #1%.pdf", "forwarded file.pdf", "second invocation.pdf")]
        for file in files:
            file.touch()
        sender = root / "sender"
        sender.mkdir()
        log = root / "application.log"
        initial_args = [files[0].name, files[1].as_uri()] if start_with_files else []
        with log.open("w") as output:
            primary = subprocess.Popen([str(binary), *initial_args], cwd=root, stdout=output, stderr=output, start_new_session=True)
            try:
                subprocess.run(["gdbus", "wait", "--session", "--timeout=15", "de.magynhard.GoblinConverter"], check=True, timeout=20)
                if start_with_files:
                    wait_for_log(primary, log, [f"Source changed (file argument): {file}" for file in files[:2]])
                else:
                    assert "Source changed (file argument)" not in log.read_text()
                # Different working directory, URI escaping and multiple files must
                # all survive forwarding to the already running primary process.
                subprocess.run([str(binary), files[2].as_uri(), "../second invocation.pdf"], cwd=sender, check=True, timeout=15)
                messages = []
                for file in files[2:]:
                    messages.extend([f"Source changed (file argument): {file}", f"Target auto-set: {file.with_name(file.stem + '_converted.pdf')}"])
                wait_for_log(primary, log, messages)
                assert primary.poll() is None
            finally:
                # AppImage runtimes may spawn the real application as a child.
                # Stop the whole group before starting the next scenario.
                try:
                    os.killpg(primary.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    primary.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(primary.pid, signal.SIGKILL)
                    primary.wait()


if __name__ == "__main__":
    binary = Path(sys.argv[1]).resolve(strict=True)
    os.environ.update(GDK_BACKEND="x11", GSK_RENDERER="cairo")
    check_opening(binary, start_with_files=True)
    check_opening(binary, start_with_files=False)
    print("File-opening checks passed: startup, multiple files, file URIs and running-instance forwarding.")
