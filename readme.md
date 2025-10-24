# 🌍 QGIS ANGEL

An **MVP Agent** that uses the **Qwen 7B AWQ model** to take user/client input and perform analysis on raster elevation DEM files, converting them into vector elevation bands. It tries to automate flood rish assessment for given region. A sample project in QGIS can be found in: https://drive.google.com/drive/folders/1mAEkFE-DC45ZgH_66xaOzWKbyLqovp4t?usp=drive_link

---

## 🚀 Setup Instructions

### 1. Copy Repository to Google Drive
- Copy all contents of this repo to a folder at the root of your Google Drive, named:

```

qgis_copilot

````

---

### 2. Open the Colab Notebook
- Open this Colab Notebook: [🔗 Google Colab Notebook](https://drive.google.com/file/d/1K0jOKwuE30mBLpi6rJlv_V0Jl0xG3hIP/view?usp=sharing)  
- A copy is also available in this repo (you can upload it manually to Colab if needed).

---

### 3. Mount Google Drive in Colab
Paste this code in the **first cell** of your notebook and run it:

```python
from google.colab import drive
drive.mount('/content/drive')
````

👉 When asked, authorize your account.

---

### 4. Setup QGIS Environment with Micromamba

Open the **Colab Terminal** and run:

```bash
cd drive/MyDrive/qgis_copilot
chmod +x setup.sh
./setup.sh
```

---

### 5. Generate Elevation Bands

Example command:

```bash
chmod +x run_elev_bands.sh
./run_elev_bands.sh proj/data/dem_filled.tif proj/data/elev_bands_5m.gpkg 5
```

This will create vector elevation bands (5 m interval) from your DEM raster.

---

## 🧠 LLM Model Setup (Qwen 7B AWQ)

> ⚠️ **Note:** Run all the following commands in the **Colab Terminal** (not in notebook cells).

---

### 0. Point to Micromamba

```bash
export PATH=/opt/mamba/bin:$PATH
```

---

### 1. Create a Clean Environment

```bash
micromamba create -y -n qgis310 python=3.10
micromamba run -n qgis310 python -V
```

---

### 2. Install PyTorch (Match CUDA)

Use the command from [PyTorch Get Started](https://pytorch.org/get-started/locally/) that matches your CUDA version. Example for CUDA 12.x:

```bash
micromamba run -n qgis310 pip install torch --index-url https://download.pytorch.org/whl/cu121
```

---

### 3. Install vLLM + Required Packages

```bash
micromamba run -n qgis310 pip install vllm transformers accelerate huggingface_hub openai
```

---

### 4. Download the Model

```bash
micromamba run -n qgis310 python - <<'PY'
from huggingface_hub import snapshot_download
print("⬇️  Downloading Qwen2-7B-Instruct-AWQ …")
p = snapshot_download("Qwen/Qwen2-7B-Instruct-AWQ",
                      local_dir="./models/qwen2-7b-instruct-awq")
print("MODEL_DIR="+p)
PY
```

---

### 5. Run vLLM Server

```bash
MODEL_DIR="./models/qwen2-7b-instruct-awq"
micromamba run -n qgis310 python -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_DIR" --quantization awq \
  --host 127.0.0.1 --port 8000 --dtype auto --max-model-len 8192
```

---

### 6. Continue in Notebook

Once the model server is running, return to your Colab notebook and execute the remaining cells.

---

## 📌 Notes

* Make sure you run terminal commands in **Colab Terminal**, not in the notebook cells (unless explicitly shown in `python` code blocks).

---

## ✅ Summary Workflow

1. Setup repo in Google Drive (`qgis_copilot`).
2. Run Colab Notebook to mount Drive.
3. Setup micromamba + QGIS environment.
4. Run `run_elev_bands.sh` to generate elevation bands.
5. Setup & run **Qwen2-7B-Instruct-AWQ** model server.
6. Continue notebook for full workflow.

---
