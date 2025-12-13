# ☕ Mimi’s Café | The Orchid Shoppe  
### PowerShell Automation Lab Environment  

> “Mimi's Cafe, Mimi's Cafe,  
> where one can study and learn and play.” 🎶  

---

## 🌸 Overview  

Welcome to **Mimi’s Café – The Orchid Shoppe**, a fully-scripted mock enterprise environment used to teach and demonstrate PowerShell automation, Active Directory management, and real-world system administration techniques.  

This lab simulates a small business financial reporting workflow, including:  

- **POS (Point-of-Sale) workstation** file output  
- **Fiscal year** data organization (October–September)  
- **Automated daily report generation**  
- **Intentional data inconsistencies** for auditing practice  
- **Automated validation and reporting**  

Each script builds on the previous one, forming a complete PowerShell training sequence.  

---

## 🧩 Project Structure  

| # | Script | Purpose |
|---|---------|----------|
| **01** | `01_Build-MockFiscalEnvironment.ps1` | Creates a full fiscal-year folder structure with daily report PDFs. |
| **02** | `02_OS_FiscalYear_FuzzyNames.ps1` | Randomly introduces naming errors to simulate staff mistakes. |
| **03** | `03_OS_FiscalYear_FuzzyAndSpecial.ps1` | Adds both fuzzy names and random “special” documents (FPO, Pavilion, Refund). |
| **04** | `04_OS_FiscalYear_DailyReport_UnifiedScan.ps1` | Audits all folders, flags fuzzy/missing files, identifies special docs, and exports a CSV report (auto-opens in Excel). |

---

## 🧠 Learning Objectives  

- Understand PowerShell folder and file automation.  
- Apply loops, conditionals, and pattern matching (`-match`, `-like`, regex).  
- Practice data validation, error handling, and logging.  
- Simulate real business automation scenarios in a safe lab.  
- Integrate PowerShell with Excel for human-readable output.  

---

## 🖥 Demo Environment  

**Active Directory Context:**  
> `MIMISCAFE.LOCAL`  
> Organizational Unit: `POS_Workgroup`  
> Shared workstation: `POS-WS01`  

Scripts may be run locally or from a central server share (e.g. `\\POS-FS01\Reports`).  

---

## 🧪 How to Run  

1. **Open PowerShell ISE** (as an instructor or student).  
2. Run each script in order:  
   ```powershell
   .\01_Build-MockFiscalEnvironment.ps1
   .\03_OS_FiscalYear_FuzzyAndSpecial.ps1
   .\04_OS_FiscalYear_DailyReport_UnifiedScan.ps1
3. Watch PowerShell color-coded output and Excel open with your audit summary!

### 🎓 Teaching Notes

> The fiscal year folder path is hard-coded in beginner scripts for clarity (I:\FY2025-2026).

> Later versions will use param() blocks and validation for professional-grade flexibility.

> The scripts demonstrate realistic automation concepts including:

> Data lifecycle management

> Human error simulation

> File auditing and compliance reporting
