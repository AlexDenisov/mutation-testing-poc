//
//  main.m
//  Mutang
//
//  Created by AlexDenisov on 29/03/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Driver.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        assert(argc == 2);
        NSString *laboratoryPath = @(argv[1]);

        Driver *driver = [Driver new];
        [driver startInLaboratory:laboratoryPath];
    }
    return 0;
}
