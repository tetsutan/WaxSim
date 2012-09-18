#import <AppKit/AppKit.h>
#import "iPhoneSimulatorRemoteClient.h"
#import "Simulator.h"
#import "termios.h"

static BOOL gReset = false;

void printUsage();
void resetSignal(int sig);

int main(int argc, char *argv[]) {
    signal(SIGQUIT, resetSignal);
    
    int c;
    char *sdk = nil;
	char *family = nil;
    char *appPath = nil;
    char *videoPath = nil;
	NSMutableArray *additionalArgs = [NSMutableArray array];
	NSMutableDictionary *environment = [NSMutableDictionary dictionary];
	NSString *environment_variable;
	NSArray *environment_variable_parts;
    
    while ((c = getopt(argc, argv, "e:s:f:v:ah")) != -1) {
        switch(c) {
			case 'e':
				environment_variable = [NSString stringWithCString:optarg encoding:NSUTF8StringEncoding];
				environment_variable_parts = [environment_variable componentsSeparatedByString:@"="];

				[environment setObject:[environment_variable_parts objectAtIndex:1] forKey:[environment_variable_parts objectAtIndex:0]];
				break;
            case 's':
                sdk = optarg;
                break;
			case 'f':
				family = optarg;
				break;
            case 'a':
                fprintf(stdout, "Available SDK Versions.\n");
                for (NSString *sdkVersion in [Simulator availableSDKs]) {
                    fprintf(stderr, "  %s\n", [sdkVersion UTF8String]);
                }
                return 1; 
            case 'h':
                printUsage();
                return 1;                 
            case 'v':
                videoPath = optarg;
                break;
            case '?':
                if (optopt == 's' || optopt == 'f') {
                    fprintf(stderr, "Option -%c requires an argument.\n", optopt);
                    printUsage();
                }
                else {
                    fprintf(stderr, "Unknown option `-%c'.\n", optopt);
                    printUsage();
                }
                return 1;
                break;
            default:
                abort ();
        }
        
    }
    
    if (argc > optind) {
        appPath = argv[optind++];

		// Additional args are sent to app
		for (int i = optind; i < argc; i++) {
			[additionalArgs addObject:[NSString stringWithUTF8String:argv[i]]];
		}
    }
    else {
        fprintf(stderr, "No app-path was specified!\n");
        printUsage();
        return 1;
    }
    
    
    NSString *sdkString = sdk ? [NSString stringWithUTF8String:sdk] : nil;
	NSString *familyString = family ? [NSString stringWithUTF8String:family] : nil;
    NSString *appPathString = [NSString stringWithUTF8String:appPath];
    NSString *videoPathString = videoPath ? [NSString stringWithUTF8String:videoPath] : nil;

    Simulator *simulator = [[Simulator alloc] initWithAppPath:appPathString sdk:sdkString family:familyString video:videoPathString env:environment args:additionalArgs];
    [simulator launch];

    if(videoPath != nil){
      [[NSRunLoop mainRunLoop] run];
    }
    else {

      // run application only
      while (simulator.launched == NO) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]]; //0.5秒
      }

    }
    return 0;
}

void printUsage() {
    fprintf(stderr, "usage: waxsim [options] app-path\n");
    fprintf(stderr, "example: waxsim -s 2.2 /path/to/app.app\n");
    fprintf(stderr, "Available options are:\n");    
    fprintf(stderr, "\t-s sdk\tVersion number of sdk to use (-s 3.1)\n");        
    fprintf(stderr, "\t-f family\tDevice to use (-f ipad)\n");
    fprintf(stderr, "\t-e VAR=value\tEnvironment variable to set (-e CFFIXED_HOME=/tmp/iphonehome)\n");
    fprintf(stderr, "\t-a \tAvailable SDKs\n");
    fprintf(stderr, "\t-v path\tOutput video recording at path\n");
    fprintf(stderr, "\t-h \tPrints out this wonderful documentation!\n");    
}

void resetSignal(int sig) {
    gReset = true;
}
