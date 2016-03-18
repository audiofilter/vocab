#ifndef APPCONFIG_H_
#define APPCONFIG_H_
#ifdef DEBUG
#define MyLog(f, ...) NSLog(f, ## __VA_ARGS__)
#else
#define MyLog(f, ...)
#endif
#endif
