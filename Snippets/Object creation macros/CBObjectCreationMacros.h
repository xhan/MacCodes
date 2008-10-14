// Created by Colin Barrett on 10/14/08.
// Copyright 2008 Colin Barrett. Released under the 3-clause BSD license, like all code in MacCode. 

#define NSDICT(...) [NSDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]
#define NSARRAY(...) [NSArray arrayWithObjects: __VA_ARGS__, nil]
#define NSBOOL(_X_) ((_X_) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse)

