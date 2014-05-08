//
//  ldapTest.m
//  SocketKit
//
//  Created by miang on 5/2/2557 BE.
//
//

#import "ldapTest.h"

#include <stdio.h>

#include "ldap.h"

#define HOSTNAME "localhost"
#define PORTNUMBER LDAP_PORT
#define BIND_DN "cn=Directory Manager"
#define BIND_PW "23skidoo"
#define NEW_DN "uid=wbjensen,ou=People,dc=localhost,dc=com"

#define NUM_MODS 5

@implementation ldapTest

void do_other_work();

int global_counter = 0;

void free_mods( LDAPMod **mods );


-(int)addASync{
    
    LDAP *ld;
    
    LDAPMessage *res;
    
    LDAPMod **mods;
    
    LDAPControl **serverctrls;
    
    char *matched_msg = NULL, *error_msg = NULL;
    
    char **referrals;
    
    int i, rc, parse_rc, msgid, finished = 0;
    
    struct timeval zerotime;
    
    char *object_vals[] = { "top", "person", "organizationalPerson", "inetOrgPerson", NULL };
    
    char *cn_vals[] = { "William B Jensen", "William Jensen", "Bill Jensen", NULL };
    
    char *sn_vals[] = { "Jensen", NULL };
    
    char *givenname_vals[] = { "William", "Bill", NULL };
    
    char *telephonenumber_vals[] = { "+1 415 555 1212", NULL };
    
    zerotime.tv_sec = zerotime.tv_usec = 0L;
    
    /* Get a handle to an LDAP connection. */
    
    if ( (ld = ldap_init( HOSTNAME, PORTNUMBER )) == NULL ) {
        
        perror( "ldap_init" );
        
        return( 1 );
        
    }
    
    /* Bind to the server as the Directory Manager. */
    
    rc = ldap_simple_bind_s( ld, BIND_DN, BIND_PW );
    
    if ( rc != LDAP_SUCCESS ) {
        
        fprintf( stderr, "ldap_simple_bind_s: %s\n", ldap_err2string( rc ) );
        
        ldap_get_lderrno( ld, &matched_msg, &error_msg );
        
        if ( error_msg != NULL && *error_msg != '\0' ) {
            
            fprintf( stderr, "%s\n", error_msg );
            
        }
        
        if ( matched_msg != NULL && *matched_msg != '\0' ) {
            
            fprintf( stderr,
                    
                    "Part of the DN that matches an existing entry: %s\n",
                    
                    matched_msg );
            
        }
        
        ldap_unbind_s( ld );
        
        return( 1 );
        
    }
    
    /* Construct the array of LDAPMod structures representing the attributes
     
     of the new entry. */
    
    mods = ( LDAPMod ** ) malloc(( NUM_MODS + 1 ) * sizeof( LDAPMod * ));
    
    if ( mods == NULL ) {
        
        fprintf( stderr, "Cannot allocate memory for mods array\n" );
        
        exit( 1 );
        
    }
    
    for ( i = 0; i < NUM_MODS; i++ ) {
        
        if (( mods[ i ] = ( LDAPMod * ) malloc( sizeof( LDAPMod ))) == NULL ) {
            
            fprintf( stderr, "Cannot allocate memory for mods element\n" );
            
            exit( 1 );
            
        }
        
    }
    
    mods[ 0 ]->mod_op = 0;
    
    mods[ 0 ]->mod_type = "objectclass";
    
    mods[ 0 ]->mod_values = object_vals;
    
    mods[ 1 ]->mod_op = 0;
    
    mods[ 1 ]->mod_type = "cn";
    
    mods[ 1 ]->mod_values = cn_vals;
    
    mods[ 2 ]->mod_op = 0;
    
    mods[ 2 ]->mod_type = "sn";
    
    mods[ 2 ]->mod_values = sn_vals;
    
    mods[ 3 ]->mod_op = 0;
    
    mods[ 3 ]->mod_type = "givenname";
    
    mods[ 3 ]->mod_values = givenname_vals;
    
    mods[ 4 ]->mod_op = 0;
    
    mods[ 4 ]->mod_type = "telephonenumber";
    
    mods[ 4 ]->mod_values = telephonenumber_vals;
    
    mods[ 5 ] = NULL;
    
    /* Send the LDAP add request. */
    
    rc = ldap_add_ext( ld, NEW_DN, mods, NULL, NULL, &msgid );
    
    if ( rc != LDAP_SUCCESS ) {
        
        fprintf( stderr, "ldap_add_ext: %s\n", ldap_err2string( rc ) );
        
        ldap_unbind( ld );
        
        free_mods( mods );
        
        return( 1 );
        
    }
    
    /* Poll the server for the results of the add operation. */
    
    while ( !finished ) {
        
        rc = ldap_result( ld, msgid, 0, &zerotime, &res );
        
        switch ( rc ) {
                
            case -1:
                
                /* An error occurred. */
                
                rc = ldap_get_lderrno( ld, NULL, NULL );
                
                fprintf( stderr, "ldap_result: %s\n", ldap_err2string( rc ) );
                
                ldap_unbind( ld );
                
                free_mods( mods );
                
                return( 1 );
                
            case 0:
                
                /* The timeout period specified by zerotime was exceeded.
                 
                 This means that the server has still not yet sent the
                 
                 results of the add operation back to your client.
                 
                 Break out of this switch statement, and continue calling
                 
                 ldap_result() to poll for results. */
                
                break;
                
            default:
                
                /* The function has retrieved the results of the add operation
                 
                 from the server. */
                
                finished = 1;
                
                /* Parse the results received from the server. Note the last
                 
                 argument is a non-zero value, which indicates that the
                 
                 LDAPMessage structure will be freed when done. (No need
                 
                 to call ldap_msgfree().) */
                
                parse_rc = ldap_parse_result( ld, res, &rc, &matched_msg, &error_msg, &referrals, &serverctrls, 1 );
                
                if ( parse_rc != LDAP_SUCCESS ) {
                    
                    fprintf( stderr, "ldap_parse_result: %s\n", ldap_err2string( parse_rc ) );
                    
                    ldap_unbind( ld );
                    
                    free_mods( mods );
                    
                    return( 1 );
                    
                }
                
                /* Check the results of the LDAP add operation. */
                
                if ( rc != LDAP_SUCCESS ) {
                    
                    fprintf( stderr, "ldap_add_ext: %s\n", ldap_err2string( rc ) );
                    
                    if ( error_msg != NULL & *error_msg != '\0' ) {
                        
                        fprintf( stderr, "%s\n", error_msg );
                        
                    }
                    
                    if ( matched_msg != NULL && *matched_msg != '\0' ) {
                        
                        fprintf( stderr,"Part of the DN that matches an existing entry: %s\n",matched_msg );
                        
                    }
                    
                } else {
                    
                    printf( "%s added successfully.\nCounted to %d while waiting for the add operation.\n",NEW_DN, global_counter );
                    
                }
                
        }
        
        /* Do other work while waiting for the results of the add operation. */
        
        if ( !finished ) {
            
            do_other_work();
            
        }
        
    }
    
    ldap_unbind( ld );
    
    free_mods( mods );
    
    return 0;
    
}

/*
 
 * Free a mods array.
 
 */

void

free_mods( LDAPMod **mods )

{
    
    int i;
    
    for ( i = 0; i < NUM_MODS; i++ ) {
        
        free( mods[ i ] );
        
    }
    
    free( mods );
    
}

/*
 
 * Perform other work while polling for results. This doesn't do anything
 
 * useful, but it could.
 
 */

void do_other_work()

{
    
    global_counter++;
    
}
@end
