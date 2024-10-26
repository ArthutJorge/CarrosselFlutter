import csv
import json
import re
from tkinter import filedialog
from tkinter import Tk
import pyperclip 

# Função para normalizar nomes de monitores (removendo ** e outros caracteres)
def normalizar_nome_monitor(nome):
    return nome.strip().replace("**", "")

# Função para formatar o horário
def formatar_horario(horario):
    # Substitui 'h' por ':' e remove espaços
    horario = horario.replace('h', ':').strip()
    # Divide o horário em horas e minutos
    horas, minutos = map(int, horario.split(':'))
    # Remove o zero à esquerda nas horas e garante que minutos sempre tenham dois dígitos
    return f"{horas}:{minutos:02d}"

# Função para selecionar arquivo
def selecionar_arquivo():
    root = Tk()
    root.withdraw()  # Oculta a janela principal
    caminho_arquivo = filedialog.askopenfilename(title="Selecione o arquivo CSV")
    return caminho_arquivo

# Mapeamento de nomes de dias em português para o JSON
dias_semana = {
    "Segunda": "segunda",
    "Terça": "terça",
    "Quarta": "quarta",
    "Quinta": "quinta",
    "Sexta": "sexta",
    "Sábado": "sábado"
}

# Função para extrair dados do CSV e gerar JSON
def gerar_json_de_csv(caminho_csv):
    monitores = {}
    horarios = []  # Lista para armazenar horários formatados
    with open(caminho_csv, mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        dias = []

        for i, row in enumerate(reader):
            # Verifica se a linha está vazia
            if all(cell == '' for cell in row):
                break  # Para a leitura se encontrar uma linha vazia

            if i == 1:  # Linha de cabeçalho de dias
                dias = [dias_semana.get(col.strip(), "") for col in row[2:]]  # Mapear dias da semana
            elif i > 1:  # Linhas de horários e monitores
                horario = row[1].strip()  # Mantém o formato original
                if not horario:
                    continue
                horario_formatado = formatar_horario(horario)  # Formata o horário
                horarios.append(horario_formatado)  # Adiciona o horário formatado à lista

                for j, cell in enumerate(row[2:]):
                    if cell.strip():
                        # Remover espaços extras e dividir por '/'
                        monitores_na_celula = re.split(r'/\s*|\)\s*', cell.strip().replace(" ", ""))
                        sala_final = None
                        if re.search(r'-\s*(Sala.+)$', cell.strip(), re.IGNORECASE):
                            sala_final = re.search(r'-\s*(Sala.+)$', cell.strip(), re.IGNORECASE).group(1)

                        for monitor_info in monitores_na_celula:
                            match = re.match(r'(\w+)(\s*\*\*)?', monitor_info.strip())
                            if match:
                                nome_monitor = normalizar_nome_monitor(match.group(1))
                                observacao = match.group(2) or ""

                                if '(' in monitor_info and ')' not in monitor_info:
                                    monitor_info += ')'

                                if nome_monitor not in monitores:
                                    monitores[nome_monitor] = {
                                        "nome": nome_monitor,
                                        "avatar": "",
                                        "horarios": {dia: [] for dia in dias_semana.values()}
                                    }

                                dia_atual = dias[j]
                                if observacao:
                                    monitores[nome_monitor]["horarios"][dia_atual].append(f"{horario_formatado} - **")
                                else:
                                    sala = re.search(r'\((Sala\s*[^)]+)\)', monitor_info, re.IGNORECASE)
                                    if sala and "adefinir" not in monitor_info:
                                        sala_str = f"{horario_formatado} - {re.sub(r'Sala', 'Sala ', sala.group(1), flags=re.IGNORECASE)}"
                                    elif sala_final and not sala:
                                        sala_final_str = re.sub(r'Sala', 'Sala ', sala_final, flags=re.IGNORECASE)  # Adiciona espaço entre "Sala" e número
                                        sala_str = f"{horario_formatado} - {sala_final_str}"
                                    elif "adefinir" in monitor_info:  # Verifica se "Sala a definir" está presente
                                        sala_str = f"{horario_formatado} - ?"
                                    else:
                                        sala_str = horario_formatado  # Sem sala ou 'Sala a definir', apenas exibir horário
                                    monitores[nome_monitor]["horarios"][dia_atual].append(sala_str)

    resultado = {
        "fisica": {
            "duracaoMonitoria": 45,
            "observacao": "",
            "horarios": horarios,  # Adiciona a lista de horários formatados
            "monitores": list(monitores.values())
        }
    }

    return resultado

# Selecionar arquivo e gerar JSON
caminho_csv = selecionar_arquivo()
json_resultado = gerar_json_de_csv(caminho_csv)

# Exibir o JSON formatado
json_formatado = json.dumps(json_resultado, ensure_ascii=False, indent=4)
pyperclip.copy(json_formatado)
print(json_formatado)