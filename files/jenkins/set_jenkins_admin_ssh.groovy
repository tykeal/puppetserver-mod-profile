import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*

// We need our script args as a List and not an array of strings
def args_list = args as List

// Strip off the first argument (it's the jenkins admin)
def jenkins_admin = args_list[0]
args_list.remove(0)

// Capture the full SSH pub key (it's all the rest of the arguments)
def sshPubKey = args_list.join(' ')

// Let's add the SSHPubKey to the jenkins_admin
// Jenkins auto-creates a user storage object when you try to get a
// specific user so there is no need to do a new
def user = hudson.model.User.get(jenkins_admin)

// We are going to assume that there is no SSH key associated with the
// user. This might bite us at some point and should probably be done in
// a more safe manner
def sshProperty = new \
  org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl(sshPubKey)

user.addProperty(sshProperty)

// save off the user modifications
user.save()
