## Script de implantação de conta de serviço gerenciado de grupo (gMSA) - Créditos Gabriel Luiz - www.gabrielluiz.com ##


#  Passo 1 - Crie sua chave raiz KDS.


# Antes de criar a chave KDS raiz, verfique se ela já foi criada como o comando abaixo:

Get-KdsRootKey


# Antes de criar uma gMSA, você precisa criar a chave KDS raiz. Esse passo é exigido apenas uma vez por domínio. Use o comando a seguir:

Add-KDSRootKey -EffectiveImmediately


# Observação: Mesmo você tendo especificado que a chave raiz deve entrar em vigor imediata mente, na verdade, ela demora 10 horas para se tornar efetiva, o que garante sua total implantação em todos os controladores do domínio.



# Dica. Para usar a chave imediatamente no ambiente de teste, você pode executar este comando:


Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10))




# Passo 2 - Crie um GMSA e vincule-o a dois (ou mais) servidores Windows.

$server1 = Get-ADComputer ADDS
$server2 = Get-ADComputer DHCP-RAS


New-ADServiceAccount -name gmsa-conta -DNSHostName gmsa-conta.gabrielluiz.local -PrincipalsAllowedToRetrieveManagedPassword $server1,$server2


# Verifique se a conta de serviço gerenciado de grupo (gMSA) foi criada como o comando abaixo:


Get-ADServiceAccount -Identity gmsa-conta -Properties PrincipalsAllowedToRetrieveManagedPassword



# Passo 3 ( Opcional) - Adicionar ou remover computadores ao gMSA.


$server1 = Get-ADComputer ADDS
$server2 = Get-ADComputer DHCP-RAS
$server3 = Get-ADComputer ADDS2

Set-ADServiceAccount -Identity gmsa-conta-agendador -PrincipalsAllowedToRetrieveManagedPassword $server1,$server2,$server3


# Observação: No meu teste eu descobri que você não pode realmente adicionar ou remover computadores individuais ao gMSA sem inserir todos os computadores de volta na lista de membros.


# Passo 4 - Instalar a conta de serviço.


# Instala o RSAT-AD-Powershell.

Add-WindowsFeature RSAT-AD-PowerShell


# Instala a conta de serviço gerenciado de grupo (gMSA) no servidor.

Install-ADServiceAccount -Identity gmsa-conta



# Testa se a conta de serviço gerenciado de grupo (gMSA) foi instalada corretamente no servidor.

Test-ADServiceAccount gmsa-conta


<#

Observações: 

Em servidores que não possui a função de ADDS instalado, exemplo, como um servidor que somente possui a função de DHCP instalado, necessário instalar o RSAT-AD-Powershell para execução do comando.


Ao executar o comando Test-ADServiceAccount o valor true significa que este servidor agora pode usar o gMSA. Se o valor for false, significa que ou o Servidor windows não foi adicionado à lista 'Principals' (usando 'New-ADServiceAccount' ou 'Set-ADServiceAccount') ou o comando 'Install-ADServiceAccount' não foi executado corretamente.

#>



# Passo 5  - Faça logon como um trabalho em lote (Log on as a batch job).

<#

Observação: 

Esta passo será demostrado em vídeo, pois se trata de uma configuração que deve ser feito por GPO para permitir que a conta de serviço gerenciado de grupo (gMSA) execute a tarefa no Agendador de Tarefas do Windows.


#>



# Passo 6  - Crie a tarefa no Agendador de Tarefas do Windows para ser executado com uma conta de serviço gerenciado de grupo (gMSA).


$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy Bypass C:\Tasks\cria-pastas-e-arquivos.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)
$principal = New-ScheduledTaskPrincipal -UserID gabrielluiz\gmsa-conta$ -LogonType Password -RunLevel highest
Register-ScheduledTask "Cria pasta e arquivos" –Action $action –Trigger $trigger –Principal $principal -Description "Tarefa de criação de pastas e arquivos"


# Passo 7 - Alterar a senha da conta de serviço gerenciado de grupo (gMSA).


# Forçar a conta de serviço gerenciado de grupo (gMSA) a alterar a senha:


Reset-ADServiceAccountPassword gmsa-conta



# Você pode então verificar a data da hora da última senha definida executando o comando:

Get-ADServiceAccount -Identity gmsa-conta -Properties passwordlastset


# Observação: O valor (data da hora da última senha definida) estará ao lado do campo 'PasswordLastSet':


# Você também pode verificar se o GMSA está fazendo login corretamente no servidor verificando o 'Último valor de login':



Get-ADServiceAccount -Identidade gmsa-conta -Propriedades LastLogonDate


# Observação: Depois de forçar uma redefinição de senha da conta de serviço gerenciado de grupo (gMSA), eu iniciaria uma execução da tarefa no Agendador de Tarefas do Windows para garantir que não tem nenhuma falha de execução.


<#

Referências:

https://docs.microsoft.com/pt-br/windows-server/security/group-managed-service-accounts/getting-started-with-group-managed-service-accounts?WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/pt-br/windows-server/security/group-managed-service-accounts/group-managed-service-accounts-overview?WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/pt-br/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/ee617223(v=technet.10)?WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/en-us/powershell/module/activedirectory/new-adserviceaccount?view=windowsserver2022-ps&WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-adserviceaccount?view=windowsserver2022-ps&WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/en-us/powershell/module/activedirectory/install-adserviceaccount?view=windowsserver2022-ps&WT.mc_id=WDIT-MVP-5003815

https://docs.microsoft.com/en-us/powershell/module/activedirectory/test-adserviceaccount?view=windowsserver2022-ps&WT.mc_id=WDIT-MVP-5003815

#>