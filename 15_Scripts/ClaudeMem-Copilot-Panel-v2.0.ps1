#Requires -Version 5.1
# VERSION 2.0.0 - FASE 6C
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Puerta=Join-Path $PSScriptRoot 'Invocar-ClaudeMem-Copilot.ps1'
$Registrador=Join-Path $PSScriptRoot 'Registrar-Observacion-Operativa-ClaudeMem.ps1'
$Historial=Join-Path $PSScriptRoot 'Gestionar-Historial-Contextos-ClaudeMem.ps1'
foreach($D in @($Puerta,$Registrador,$Historial)){if(-not(Test-Path -LiteralPath $D -PathType Leaf)){throw "Falta dependencia: $D"}}
$Form=New-Object Windows.Forms.Form
$Form.Text='ClaudeMem para Copilot - Evaluacion integrada';$Form.Size=New-Object Drawing.Size(1040,790);$Form.StartPosition='CenterScreen'
$Lbl=New-Object Windows.Forms.Label;$Lbl.Text='Consulta';$Lbl.Location=New-Object Drawing.Point(15,15);$Lbl.AutoSize=$true
$Txt=New-Object Windows.Forms.TextBox;$Txt.Location=New-Object Drawing.Point(15,38);$Txt.Size=New-Object Drawing.Size(990,58);$Txt.Multiline=$true
$Nivel=New-Object Windows.Forms.ComboBox;$Nivel.Location=New-Object Drawing.Point(15,108);$Nivel.Width=95;$Nivel.DropDownStyle='DropDownList';[void]$Nivel.Items.AddRange(@('1','2','3'));$Nivel.SelectedItem='2'
$Max=New-Object Windows.Forms.NumericUpDown;$Max.Location=New-Object Drawing.Point(125,108);$Max.Minimum=500;$Max.Maximum=16000;$Max.Value=5000;$Max.Increment=500
$Btn=New-Object Windows.Forms.Button;$Btn.Text='Generar contexto';$Btn.Location=New-Object Drawing.Point(275,105);$Btn.Width=145
$Exportar=New-Object Windows.Forms.Button;$Exportar.Text='Exportar Markdown';$Exportar.Location=New-Object Drawing.Point(435,105);$Exportar.Width=145;$Exportar.Enabled=$false
$Hist=New-Object Windows.Forms.Button;$Hist.Text='Ver historial';$Hist.Location=New-Object Drawing.Point(595,105);$Hist.Width=110
$Estado=New-Object Windows.Forms.Label;$Estado.Location=New-Object Drawing.Point(15,140);$Estado.Size=New-Object Drawing.Size(990,23);$Estado.Text='LISTO'
$Salida=New-Object Windows.Forms.RichTextBox;$Salida.Location=New-Object Drawing.Point(15,168);$Salida.Size=New-Object Drawing.Size(990,425);$Salida.ReadOnly=$true;$Salida.Font=New-Object Drawing.Font('Consolas',9)
$Grupo=New-Object Windows.Forms.GroupBox;$Grupo.Text='Evaluacion del ultimo paquete';$Grupo.Location=New-Object Drawing.Point(15,602);$Grupo.Size=New-Object Drawing.Size(990,130);$Grupo.Enabled=$false
$LblRel=New-Object Windows.Forms.Label;$LblRel.Text='Relevancia';$LblRel.Location=New-Object Drawing.Point(12,28);$LblRel.AutoSize=$true
$Rel=New-Object Windows.Forms.NumericUpDown;$Rel.Location=New-Object Drawing.Point(85,26);$Rel.Minimum=0;$Rel.Maximum=5;$Rel.Value=4
$LblRes=New-Object Windows.Forms.Label;$LblRes.Text='Resultado';$LblRes.Location=New-Object Drawing.Point(155,28);$LblRes.AutoSize=$true
$Res=New-Object Windows.Forms.ComboBox;$Res.Location=New-Object Drawing.Point(220,25);$Res.Width=210;$Res.DropDownStyle='DropDownList';[void]$Res.Items.AddRange(@('SIN_ERROR','SIN_RESULTADOS','POCO_RELEVANTE','ERROR_PANEL','FALSO_POSITIVO_SEGURIDAD','OTRO'));$Res.SelectedItem='SIN_ERROR'
$LblCom=New-Object Windows.Forms.Label;$LblCom.Text='Comentario';$LblCom.Location=New-Object Drawing.Point(12,62);$LblCom.AutoSize=$true
$Com=New-Object Windows.Forms.TextBox;$Com.Location=New-Object Drawing.Point(85,59);$Com.Size=New-Object Drawing.Size(745,52);$Com.Multiline=$true
$Evaluar=New-Object Windows.Forms.Button;$Evaluar.Text='Registrar evaluacion';$Evaluar.Location=New-Object Drawing.Point(842,58);$Evaluar.Size=New-Object Drawing.Size(130,52)
$Grupo.Controls.AddRange(@($LblRel,$Rel,$LblRes,$Res,$LblCom,$Com,$Evaluar))
$script:Ultimo=$null;$script:Inicio=$null
$Btn.Add_Click({
 try{$Btn.Enabled=$false;$Grupo.Enabled=$false;$Estado.Text='AUDITANDO Y GENERANDO...';$Form.Refresh();$script:Inicio=Get-Date;$R=&$Puerta -Consulta $Txt.Text -Nivel ([int]$Nivel.SelectedItem) -MaxCaracteres ([int]$Max.Value) -ModoSalida OBJETO;$script:Ultimo=$R;$Salida.Text=$R.markdown;$Estado.Text="APROBADO | $($R.resultados) resultados | $($R.caracteresUsados) caracteres";$Exportar.Enabled=$true;$Grupo.Enabled=$true;if([int]$R.resultados-eq0){$Rel.Value=0;$Res.SelectedItem='SIN_RESULTADOS'}else{$Rel.Value=4;$Res.SelectedItem='SIN_ERROR'}
 }catch{$Estado.Text='BLOQUEADO';[Windows.Forms.MessageBox]::Show($_.Exception.Message,'ClaudeMem')|Out-Null}finally{$Btn.Enabled=$true}
})
$Evaluar.Add_Click({
 try{if($null-eq$script:Ultimo){throw 'No existe un paquete generado.'};$Seg=[int][math]::Max(0,((Get-Date)-$script:Inicio).TotalSeconds);$Reg=&$Registrador -Consulta $script:Ultimo.consulta -PaqueteId $script:Ultimo.paqueteId -Relevancia ([int]$Rel.Value) -TiempoSegundos $Seg -Resultado ([string]$Res.SelectedItem) -Comentario $Com.Text;if($Reg.estado-eq'ACEPTADA'){$Estado.Text='EVALUACION ACEPTADA';$Grupo.Enabled=$false}else{$Estado.Text='EVALUACION EN CUARENTENA'}
 }catch{$Estado.Text='ERROR DE EVALUACION';[Windows.Forms.MessageBox]::Show($_.Exception.Message,'ClaudeMem')|Out-Null}
})
$Exportar.Add_Click({$D=New-Object Windows.Forms.SaveFileDialog;$D.Filter='Markdown (*.md)|*.md';$D.FileName='Contexto-Copilot.md';if($D.ShowDialog()-eq[Windows.Forms.DialogResult]::OK){[IO.File]::WriteAllText($D.FileName,$script:Ultimo.markdown,[Text.UTF8Encoding]::new($true));$Estado.Text="EXPORTADO: $($D.FileName)"}})
$Hist.Add_Click({try{$Salida.Text=(&$Historial -Listar -Ultimos 20|Format-Table -AutoSize|Out-String);$Estado.Text='HISTORIAL MOSTRADO'}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'ClaudeMem')|Out-Null}})
$Form.Controls.AddRange(@($Lbl,$Txt,$Nivel,$Max,$Btn,$Exportar,$Hist,$Estado,$Salida,$Grupo))
[void]$Form.ShowDialog()
