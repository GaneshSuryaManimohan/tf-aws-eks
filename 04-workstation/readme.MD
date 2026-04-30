# Installing eksctl on Linux (amd64)

* This section explains how to download, verify, and install the latest version of eksctl.

* eksctl is a CLI tool used to create and manage Kubernetes clusters on Amazon EKS.

---

## Step 1: Set Architecture and Platform

```bash
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
```

* **What this does:**

1. `ARCH=amd64`
    - Defines the system architecture (64-bit Intel/AMD).

2. `uname -s`
    - Returns the operating system name (e.g., Linux).

3. `PLATFORM=$(uname -s)_$ARCH`
    - Combines OS and architecture to form: `Linux_amd64`

This ensures the correct binary is downloaded for your system.

---

## Step 2: Download the Latest Release

```curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"```

* **Explanation:**

1. curl → Used to download files from the internet

2. -s → Silent mode

3. -L → Follow redirects

4. -O → Save file with original name

This downloads: `eksctl_Linux_amd64.tar.gz`

---

## Step 3: Verify File Integrity (Checksum Validation)

```curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check```

* **Why this is important:**

1. This step ensures the downloaded file is not corrupted or tampered with.

2. Downloads official checksum file

3. Filters checksum for your platform

4. Verifies it using sha256sum

If successful, you will see: `eksctl_Linux_amd64.tar.gz: OK`

---

## Step 4: Extract the Binary

`tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz`

* **Explanation:**

1. tar -xzf → Extract compressed tar file

2. -C /tmp → Extract into /tmp directory

3. rm → Remove archive after extraction

Now the eksctl binary exists at: `/tmp/eksctl`

---

## Step 5: Install Binary System-Wide

`sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl`

* **Explanation:**

1. install → Copies file and sets permissions

2. -m 0755 → Sets executable permissions

3. /usr/local/bin → Common directory for user-installed binaries

This makes eksctl accessible globally from the terminal.

---

## Step 6: Verify Installation

`eksctl version`

Example output: `0.223.0`

If a version is displayed, installation was successful.

---

## Summary of What Happens

1. Detect system OS and architecture

2. Download correct eksctl binary

3. Verify checksum for security

4. Extract binary

5. Install to /usr/local/bin

6. Confirm installation

---

## Best Practice Note

- Always verify checksums before installing binaries from the internet.
- Skipping the checksum step can expose your system to corrupted or malicious files.