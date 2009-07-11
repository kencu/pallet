//
//  MPPortProcess.m
//  MacPorts.Framework
//
//  Created by Juan Germán Castañeda Echevarría on 7/9/09.
//  Copyright 2009 UNAM. All rights reserved.
//

#import "MPPortProcess.h"

@interface MPPortProcess (PrivateMethods)

- (void)initializeInterpreter;

@end


@implementation MPPortProcess

- (id)initWithPKGPath:(NSString*)path {
    PKGPath = path;
    [self initializeInterpreter];
    return self;
}

- (oneway void)evaluateString:(byref id)statement {
    // TODO Handle the posible errors and notifications
    Tcl_Eval(interpreter, [statement UTF8String]);
}

#pragma mark Private Methods

- (void)initializeInterpreter {
    // Create interpreter
    interpreter = Tcl_CreateInterp();
	if(interpreter == NULL) {
		NSLog(@"Error in Tcl_CreateInterp, aborting.");
	}
    // Initialize interpreter
    if(Tcl_Init(interpreter) == TCL_ERROR) {
		NSLog(@"Error in Tcl_Init: %s", Tcl_GetStringResult(interpreter));
		Tcl_DeleteInterp(interpreter);
	}
    // Load macports_fastload.tcl from PKGPath/macports1.0
    NSString * mport_fastload = [[@"source [file join \"" stringByAppendingString:PKGPath]
								 stringByAppendingString:@"\" macports1.0 macports_fastload.tcl]"];
	if(Tcl_Eval(interpreter, [mport_fastload UTF8String]) == TCL_ERROR) {
		NSLog(@"Error in Tcl_EvalFile macports_fastload.tcl: %s", Tcl_GetStringResult(interpreter));
		Tcl_DeleteInterp(interpreter);
	}
    // TODO Load distributed object messaging methods
    
    // TODO load portProcessInit.tcl
}

@end

int main(int argc, char const * argv[]) {
    NSConnection *portProcessConnection; 
    portProcessConnection = [NSConnection defaultConnection];
    NSString *PKGPath = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
    MPPortProcess *portProcess = [[MPPortProcess alloc] initWithPKGPath:PKGPath];
    
    // Vending portProcess
    [portProcessConnection setRootObject:portProcess]; 
    
    // Register the named connection
    if ( [portProcessConnection registerName:@"MPPortProcess"] ) {
        NSLog( @"Successfully registered connection with port %@", 
              [[portProcessConnection receivePort] description] );
    } else {
        NSLog( @"Name used by %@", 
              [[[NSPortNameServer systemDefaultPortNameServer] portForName:@"MPPortProcess"] description] );
    }
    
    // TODO Send a ready signal to "delegate"
    
    // Wait for any message
    [[NSRunLoop currentRunLoop] run];
    return 0;
}