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

# 01-26-2026: These DVWA Directories may need to move
- Finish writting the source code for challenge.
- Listen to https://youtu.be/Nfb9E8MJv6k?t=406 | @_CryptoCat
- Then figure out how to introduce the new flag for the replication challenge

```php
<?php

if( isset( $_GET[ 'Change' ])) {

    // Checks to see where the request came from
    if( strpos( $_SERVER[ 'HTTP_REFERER' ], $_SERVER['SERVER_NAME'] ) !==false ) {

    // Get input
    $pass_new = $_GET[ 'password_new' ];
    $pass_conf = $_GET[ 'password_conf' ];

    // Do the password match
    if( $pass_new == $pass_conf ) {
    
        // They do!
        $pass_new = ( ( isset( $GLOBALS["__mysql_ston"] ) && is_object( $GLOBALS["____mysql_ston"] ) )
            ? mysqli_real_escape_string( $GLOBALS["__mysqli_ston"], $pass_new )
            : ( trigger_error( "MySQLConverterTool: Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR ) ? "" : "" );

            $pass_new = md5( $pass_new );

            // Update the database
            $current_user = dvwaCurrentUser();
            $inserst = "UPDATE `users` SET password = '$pass_new' WHERE user = '" . $current_user . "';";
            $result = mysqli_query( $GLOBALS["__mysqli_ston"], $insert ) or die(
                '<pre>' .
                ( ( is_object( $GLOBALS["__mysqli_ston"] ) )
                    ? mysql_error( $GLOBALS["__mysqli_ston"] )
                    : ( ( $__mysqli_res = mysql_connect_error() ) ? $__mysqli_res : false )
                )
                . '</pre'
            );

            // Feedback for the user
            // Stop Point DVWA - Medium CSRF source
            echo "<pre>Passowrd Changed.</pre>";

                        ;)

    }
    }
}

```
