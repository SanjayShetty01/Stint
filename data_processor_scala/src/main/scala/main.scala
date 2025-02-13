import DatasetExtractor.{downloadZipFile, unzipFile}

@main
def main(): Unit = {
  downloadZipFile(url = "https://www.kaggle.com/api/v1/datasets/download/rohanrao/formula-1-world-championship-1950-2020",
    targetPath = "downloads/dataset.zip")
  unzipFile(zipFilePath = "downloads/dataset.zip", outputDir = "downloads/data/")
  print("LFGGGGGGGGGGGG")
}

