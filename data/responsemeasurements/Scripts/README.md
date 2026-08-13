# Response Measurements - Scripts Directory

This directory centralizes all analysis, compilation, and visualization scripts for the **Response Measurements** data. 
Like the onboard measurements, scripts are no longer scattered in various board or week folders—they are neatly categorized here by their function.

---

## 📂 Directory Structure

### 1. `Response_Metrics_Analysis/`
These scripts compile all of the library-based response measurements (Gauss vs Ohms, Sensitivity, MR Ratio) into cleanly formatted Excel summary sheets. They group the data by Sensor Block (e.g., B1, B2) and pivot the metrics out for sensors A-F.

- **`Hsin_Tings_Board_Analysis.py`**
  - **Target:** LibraryBased Week 5 `Hsin_Tings_Board` data.
  - **Output:** Saves `Analysis_Summary.xlsx` in the `Hsin_Tings_Board` folder.
- **`Peters_Board_Analysis.py`**
  - **Target:** LibraryBased Week 5 `Peters_Board` data.
  - **Output:** Saves `Analysis_Summary.xlsx` in the `Peters_Board` folder.

**How to run (Python):**
```bash
python Response_Metrics_Analysis/Peters_Board_Analysis.py
```

---

### 2. `Gaussmeter_Visualizers/`
These scripts were used for plotting the raw Gaussmeter calibration sweeps (from Week 1 and Week 2).
- `Hsin_Tings_Week1_visualize.py`
- `Peters_Week1_visualize.py`
- `Peters_Week2_visualize.py`

*(Note: If you run these, they may still expect to be in their original folders, so they serve mostly as reference for the previous Gaussmeter plotting logic).*

---

### 3. `Data_Compilers/`
- **`compile_tmr_data.m`**: The main MATLAB compiler script previously located in `CompilerScripts/`. Used for aggregating raw TMR output.

---

### 4. `Legacy_Analysis_Scripts/`
This folder is the archive for all the random `style.m`, `linear.m`, and experimental parsing scripts that were created during earlier analysis attempts. 

---

## 🚀 General Notes
- To run any python script, ensure you are in the virtual environment:
  ```bash
  # From the root of the project:
  python data/responsemeasurements/Scripts/Response_Metrics_Analysis/script_name.py
  ```
