<?php

/*
===========================================================
DVWA – CSRF Vulnerability (Medium Security Level)
Source Code Review & Learning Notes
===========================================================

This file demonstrates an insecure implementation of CSRF
protection used for training and educational purposes.

Key Characteristics of Medium CSRF:

1. CSRF Protection Mechanism
   - Relies solely on checking the HTTP_REFERER header
   - Assumes requests originating from the same server name
     are trustworthy
   - This approach is insecure because HTTP_REFERER can be
     spoofed, stripped, or manipulated by the client

2. Request Method Weakness
   - Sensitive operations (password changes) are handled
     using the GET method
   - GET parameters may be logged, cached, bookmarked, or
     leaked via browser history and referrer headers

3. Missing CSRF Token
   - No unpredictable, session-bound CSRF token is used
   - The application cannot distinguish legitimate user
     actions from forged cross-site requests

4. Authentication Context Assumption
   - The application assumes the user is already authenticated
     and blindly trusts incoming requests with valid cookies
   - Browsers automatically attach session cookies to forged
     requests

5. Cryptographic Weakness
   - Passwords are hashed using MD5
   - MD5 is deprecated and vulnerable to brute-force and
     rainbow table attacks
   - No salting or modern password hashing is implemented

6. Input Handling
   - Password input is escaped for SQL usage
   - SQL injection is partially mitigated, but logic flaws
     remain exploitable

7. Educational Purpose
   - This code is intentionally vulnerable
   - It demonstrates why referer-based CSRF defenses are
     insufficient and should not be used in production

Real-World Secure Design Would Require:
   - POST requests for state-changing actions
   - Per-request CSRF tokens bound to user sessions
   - Server-side token validation
   - Modern password hashing (bcrypt, Argon2)
   - Defense-in-depth controls

===========================================================
End of Medium CSRF Source Notes
===========================================================
*/

//The above comments we copied in 

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
        }
        else {
            // Issue with password matching
            echo "<pre>Passowrds did not match.</pre>";
        }        
    }
    else {
        // Didn't come from a trusted source
        echo "<pre>That request didn't look correct.</pre>";
    }
    
    ((is_null)$__mysqli_res = mysqli_close($GLOBALS["__mysql_ston"]))) ? false : $__mysqli_res);
}

?>

