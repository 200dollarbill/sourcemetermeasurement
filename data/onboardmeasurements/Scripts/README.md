# Onboard Measurements - Scripts Directory

This directory centralizes all analysis and correlation scripts for the **Onboard Measurements** data. 
Instead of being scattered across the board directories, they are now neatly grouped by their purpose. The scripts are smart enough to automatically locate their respective datasets, so you can just run them from here!

---

## 📂 Directory Structure

### 1. `Implied_Field_Correlation/`
These scripts correlate the onboard measurements with the true sensitivities measured on the gaussmeter (response measurements). They calculate the implied generated magnetic field, find the Gauss/Ampere correlation, output high-quality `.png`/`.fig` hysteresis plots, and export an `Correlation_Summary.xlsx`.

- **`Hsin_Tings_Board_Correlation.m`** & **`Hsin_Tings_Board_Correlation.py`**
  - **Target:** `Hsin_Tings_Board` data.
  - **Output:** Saves plots and Excel summaries into `Hsin_Tings_Board/Analysis/ImpliedField_Python` (or `ImpliedField` for MATLAB).
- **`Peters_Board_Correlation.m`** & **`Peters_Board_Correlation.py`**
  - **Target:** `Peters_Board` data.
  - **Output:** Saves plots and Excel summaries into `Peters_Board/Analysis/ImpliedField_Python` (or `ImpliedField` for MATLAB).

**How to run (Python):**
```bash
python Implied_Field_Correlation/Peters_Board_Correlation.py
```
*(For MATLAB scripts, simply open them in the MATLAB IDE and press Run).*

---

### 2. `Onboard_Metrics_Analysis/`
These scripts are responsible for bulk-compiling raw sensor data (MR Ratio, Sensitivity, Nominal Resistance, Hysteresis Gaps) and formatting them into clean, multi-sheet pivot tables grouped by Sensor Blocks.

- **`Peters_Board_Analysis.py`**
  - **Target:** `Peters_Board` onboard measurements.
  - **Output:** Creates `Peters_Board/Analysis_Summary.xlsx`.
  - **Details:** Automatically sorts sensors A-F, separates pin groups (A-F vs G-L), and correctly detects hysteresis gaps.

**How to run:**
```bash
python Onboard_Metrics_Analysis/Peters_Board_Analysis.py
```

---

### 3. `Legacy_Styling_Scripts/`
This folder acts as an archive for older, one-off MATLAB scripts (like `linear.m`, `style_rmse.m`, etc.) that were previously scattered inside deep Analysis folders. They are preserved here in case you need to reference old formatting logic or specific calculations.

---

## 🚀 General Notes
- All Python scripts require `pandas`, `numpy`, `matplotlib`, and `xlsxwriter`/`openpyxl`. They are already installed in your `venv`.
- To run any python script, ensure you are using the virtual environment:
  ```bash
  # From the root of the project:
  python data/onboardmeasurements/Scripts/.../script_name.py
  ```
