/**************************************************************/
/* ktopits -                                                  */
/* Axway.h                                                   */
/* KT 09-JUN-2014                                             */
/**************************************************************/

//ALL APP SPECIFIC STUFF IS HERE

//API SERVICES PORTAL
#define USE_APIGEE_SERVICES 0
#define USE_AXWAY_PUSH 1

//Settings in root.plist
//ALL APPS (DELEGATE)
#define SETTING_version             @"version_preference"		// string (Read-Only)
#define SETTING_release             @"release_preference"		// string (Read-Only)

//APP SPECIFIC
#define SETTING_hostname            @"host_name"				// String
#define SETTING_oauth2              @"oauth_string2"			// String
#define SETTING_oauth3              @"oauth_string3"			// String
#define SETTING_service				@"service_integer"			// Integer


//Apple (axw://....) - MUST MATCH INFO.PLIST!!!
#define API_SCHEME @"apiworkshop"
//NOT THE SAME AS WINDOWS/OSX "HOSTS"

//END

