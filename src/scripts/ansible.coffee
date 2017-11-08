# Description:
#   Erweitert Hubot um die Fähigkeit Ansible Playbooks auszuführen
#
# Dependencies:
#   "shelljs": ">= 0.5.3"
#
# Configuration:
#   HUBOT_ANSIBLE_INVENTORY_FILE - The inventory file
#   HUBOT_ANSIBLE_PRIVATE_KEY - The private key file
#   HUBOT_ANSIBLE_REMOTE_USER - Remote user
# Commands:
#   hubot ansible <host> <Befehl> - Führe den Befehl auf dem Host ausd
#   hubot ansible playbook <Host>[,<Host>,..] <Playbook.yml> - Startet das gewählte Playbook auf ausgewählten Hosts
#   hubot ansible log <Host> <Logfile>  [<Anzahl der auszugebenen Zeilen>] - Gibt das gewünschte Logfile aus [mit ausgewählter Anzahl Zeilen]
# Author:
#   vspiewak
#   Christian Koehler

inventory =  process.env.HUBOT_ANSIBLE_INVENTORY_FILE
private_key = process.env.HUBOT_ANSIBLE_PRIVATE_KEY
remote_user = process.env.HUBOT_ANSIBLE_REMOTE_USER
playbook_dir = process.env.HUBOT_ANSIBLE_PLAYBOOK_DIR


display_result = (robot, res, hosts, user, command, text) ->
  res.reply "#{user}@#{hosts}: #{command}\n#{text}"

display_result_log = (robot, res, hosts, user, text, logdatei) ->
  res.reply "#{user}@#{hosts}: #{logdatei} \n#{text}"

run_ansible = (robot, hosts, remote_user, command, res) ->
  shell = require('shelljs')
  #ansible = "ansible -i #{inventory} --private-key=#{private_key} #{hosts} -u #{remote_user} -m shell -a \"#{command}\""
  ansible = "ansible #{hosts} \"#{command}\""
  shell.exec ansible, {async:true}, (code, output) ->
    display_result robot, res, hosts, remote_user, command, output

run_ansible_playbook = (robot, hosts, remote_user, command, res) ->
  shell = require('shelljs')
  ansible = "cd #{playbook_dir} && ansible-playbook #{command} --limit #{hosts}"
  shell.exec ansible, {async:true}, (code, output) ->
    display_result robot, res, hosts, remote_user, command, output

run_ansible_playbook_log = (robot, hosts, remote_user, laenge, res, logdatei) ->
  shell = require('shelljs')
  parameter = "--extra-vars='zeilen=#{laenge}' --extra-vars='logfile=#{logdatei}'"
  yml = "logfiles.yml"
  ansible = "cd #{playbook_dir} && ansible-playbook #{yml} --limit #{hosts} #{parameter}"
  console.log("ansible Befehl: ----------- #{ansible}")
  shell.exec ansible, {async:true}, (code, output) ->
    console.log("Logdatei------------------------------ #{logdatei}")
    display_result_log robot, res, hosts, remote_user, output, logdatei

module.exports = (robot) ->

  robot.respond /ansible\s+([\S-.]+)\s+(.+)/i, (res) ->
    hosts = res.match[1].trim()
    if hosts != "playbook" and hosts !=  "log" 
      command = res.match[2].trim()
      run_ansible robot, hosts, remote_user, command, res
    

  robot.respond /ansible playbook\s+([\S-.]+)\s+(.+)/i, { id: 'asnible-approval.test', approval: { group: 'test'} }, (res) ->
    hosts = res.match[1].trim()
    command = res.match[2].trim()
    run_ansible_playbook robot, hosts, remote_user, command, res

  robot.respond /ansible log\s+(\S+)\s+(\S+)\s*(\d*)/i, { id: 'asnible-approval.test', approval: { group: 'test'} }, (res) ->
    hosts = res.match[1].trim()
    logdatei = res.match[2].trim()
    laenge = res.match[3].trim()
    if laenge.length == 0 
      laenge = 10
    run_ansible_playbook_log robot, hosts, remote_user, laenge, res, logdatei
  
  robot.respond /ansible hilfe/i, (msg) ->
    msg.send "Derzeit verfügbare Ansible Playbooks \n datum.yml: dient zum Ausgeben der Uhrzeit"

