.imageScanStatus.status == "COMPLETE"
and (
  (.imageScanFindings.findingSeverityCounts.CRITICAL // 0)
  + (.imageScanFindings.findingSeverityCounts.HIGH // 0) == 0
)
