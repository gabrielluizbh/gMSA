## Script de criação de pasta e arquivo de texto baseado na data - Créditos Gabriel Luiz - www.gabrielluiz.com ##


# Busca a data.

$data = Get-Date -Format "MM-dd-yyyy-HH-mm"
$nome = “$data”


# Cria uma pasta com o nome da data.

New-Item -Path C:\"$data" -ItemType Directory


# Cria um arquivo de texto vazio com o nome da data. 

New-Item -Path C:\"$data"\"$data".txt -ItemType File


<#

Observação: Este script foi criado apenas para testar o Agendador de Tarefas do Windows utilizando a conta de serviço gerenciado de grupo (gMSA).


#>