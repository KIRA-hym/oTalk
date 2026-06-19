import pandas as pd
file_path = r'C:\Users\HYM\Documents\카카오톡 받은 파일\벙참 시트.xlsx'
try:
    df = pd.read_excel(file_path, sheet_name='방인원 벙 참여', nrows=20)
    print(df.head(10).to_string())
    print('\nColumns:', df.columns.tolist())
except Exception as e:
    print('Error:', e)
