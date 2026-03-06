# Start Menu Tweaks Repository

This repository contains a collection of Start Menu tweaks and tools, along with scripts to automate their setup on Windows systems.

## Repository Contents

- **StartMenuTweaks**: A collection of files and settings for customizing the Windows Start Menu.
- **wgetStartMenus.lookmomnohands**: A PowerShell script that downloads the latest Start Menu tweaks and installs the HP Image Assistant.

## Getting Started

### Prerequisites

- Windows 11
- PowerShell (version 5.0 and above)

### Installation

1. **Clone the Repository or Download the ZIP File**:
   - ```bash
     git clone https://github.com/lookmomnohands/laughing-chainsaw.git
     ```
   
2. **Navigate to the Directory**:
   - ```bash
     cd StartMenuTweaks
     ```

3. **Run the PowerShell Script as Administrator**:
   - Right-click on `wgetStartMenus.ps1` and select **Run with PowerShell**.
   - The script will:
     - Download the latest ZIP containing Start Menu tweaks.
     - Extract the contents to `C:\`.
     - Download the latest version of the HP Image Assistant.
     - Install the HP Image Assistant silently.

### Usage

To run the script automatically as SYSTEM, create a task in **Task Scheduler** with the `wgetStartMenus.lookmomnohands` script, ensuring the following settings:
- **Run with highest privileges**
- **Trigger** according to your preference (e.g., at startup).

### Expected Output

You will see logs in the PowerShell console detailing:
- The number of files extracted from the ZIP.
- The downloading process of the HP Image Assistant.
- Confirmation of the installation status.

### Contributing

Contributions are welcome! If you have suggestions for improvements or find issues, please submit a pull request or open an issue.

### License

This project is licensed under the MIT License.
