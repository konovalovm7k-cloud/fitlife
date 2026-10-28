"""Select an available iPhone without assuming a specific runner image/model."""
import json
import os
import subprocess


def main():
    result = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"])
    devices = json.loads(result)["devices"]
    phones = [d for runtime in sorted(devices, reverse=True) for d in devices[runtime]
              if "iPhone" in d["name"] and d.get("isAvailable")]
    if not phones:
        raise SystemExit("No available iPhone simulator on this runner")
    phone = phones[0]
    if phone["state"] != "Booted":
        subprocess.run(["xcrun", "simctl", "boot", phone["udid"]], check=True)
    subprocess.run(["xcrun", "simctl", "bootstatus", phone["udid"], "-b"], check=True)
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as target:
        target.write(f'FITLIFE_SIMULATOR={phone["udid"]}\n')
    print(f'Selected {phone["name"]}')


if __name__ == "__main__":
    main()
