import requests
from bs4 import BeautifulSoup
import pandas as pd

url = "https://pricepertoken.com"
headers = {"User-Agent": "Mozilla/5.0"}

response = requests.get(url, headers=headers)
soup = BeautifulSoup(response.text, "html.parser")

table = soup.find("table")
rows = []

# Cabeceras
headers_row = [th.get_text(strip=True) for th in table.find("tr").find_all("th")]
# Filas
for tr in table.find_all("tr")[1:]:
    tds = tr.find_all("td")
    if not tds:
        continue

    cells = []

    # 1) Primera columna: solo el texto del span.truncate
    first_td = tds[0]
    span = first_td.find("span", class_="truncate")
    name = span.get_text(strip=True) if span else first_td.get_text(strip=True)
    cells.append(name)

    # 2) Resto de columnas: igual que antes
    for td in tds[1:]:
        cells.append(td.get_text(strip=True))

    rows.append(cells)



df = pd.DataFrame(rows, columns=headers_row)
df = df.iloc[:, :-1]
print(df.head())

df.to_csv("pricepertoken.csv", index=False, sep=",")
print(f"Guardado: {len(df)} modelos")
