# Use the dvwa to learn how to create challenges
- modify existing challenges [x]
- create arbituary flags [x]
- use flags to answer questions []
- Modify entry point dashboard no esxi host - config static host-vm links

# Workflow:
- Onsite: User performs POS task e.g. Batch Out ect
- User is at terminal when done they launch the cyber-dash launcher
- The cyber dash launcer will introduce task of the day e.g. website with a button
- The button on click will initialize the next process (son)/client
- Use 1st DVWA flag as a practice run and way to tie this part together 
- !!! Firewall setting between POS <---> R3

# Now stable: 
- Move the vulnerable (windows server/dvwa/xampp/juice-shop/) to ~/servers
- Create dhcp reservations on R3
- Create reservation for the client ubuntu machine
- Create users and users group - later practice Ansible.builtin and .yaml
- Prepare host list on the 172. subnet    
