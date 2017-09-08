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
#   hubot ansible <host> <command> - Execute the command on the hosts
#   hubot ansible-playbook <Host>[,<Host>,..] <Playbook.yml> - Startet das gewählte Playbook auf ausgewählten Hosts
#
# Author:
#   vspiewak
#   Christian Koehler

inventory =  process.env.HUBOT_ANSIBLE_INVENTORY_FILE
private_key = process.env.HUBOT_ANSIBLE_PRIVATE_KEY
remote_user = process.env.HUBOT_ANSIBLE_REMOTE_USER
playbook_dir = process.env.HUBOT_ANSIBLE_PLAYBOOK_DIR


display_result = (robot, res, hosts, user, command, text) ->
  res.reply "#{user}@#{hosts}: #{command}\n#{text}"


run_ansible = (robot, hosts, remote_user, command, res) ->
  shell = require('shelljs')
  ansible = "ansible -i #{inventory} --private-key=#{private_key} #{hosts} -u #{remote_user} -m shell -a \"#{command}\""
  shell.exec ansible, {async:true}, (code, output) ->
    display_result robot, res, hosts, remote_user, command, output

run_ansible_playbook = (robot, hosts, remote_user, command, res) ->
  shell = require('shelljs')
  ansible = "cd #{playbook_dir} && ansible-playbook #{command} --limit #{hosts}"
  shell.exec ansible, {async:true}, (code, output) ->
    display_result robot, res, hosts, remote_user, command, output

module.exports = (robot) ->

  robot.respond /ansible\s+([\w-.]+)\s+(.+)/i, (res) ->
    hosts = res.match[1].trim()
    command = res.match[2].trim()
    run_ansible robot, hosts, remote_user, command, res



  robot.respond /ansible-playbook\s+([\w-.]+)\s+(.+)/i, { id: 'asnible-approval.test', approval: { group: 'test'} }, (res) ->
    hosts = res.match[1].trim()
    command = res.match[2].trim()
    console.log "Host: #{hosts}   Command: #{command}"
    run_ansible_playbook robot, hosts, remote_user, command, res


