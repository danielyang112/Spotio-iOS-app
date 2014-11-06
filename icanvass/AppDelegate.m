//
//  AppDelegate.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//


#import "AppDelegate.h"
#import "ICRequestManager.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "MMDrawerController/MMDrawerController.h"
#import <GoogleMaps/GoogleMaps.h>
#import <FreshdeskSDK/FreshdeskSDK.h>
#import "Users.h"
#import "Mixpanel.h"
#import <BugSense-iOS/BugSenseController.h>
#import "FanOut.h"

#define kGoogleAPIKey @"AIzaSyAdd2d-Ukg6NwqHRQUY8ltgnbTcIUamS1I"
#define kFreshDeskSite @"spotio.freshdesk.com"
#define kFreshDeskAPIKey @"CPEiBLBk9moDrw2ix3R"
#define kMixPanelToken @"3d3406adba1edf53af7443468c7efad8"
#define kFanOutRealm @"3f449354"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize fetchResultController = _fetchResultController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [BugSenseController sharedControllerWithBugSenseAPIKey:@"9ebe29b0"
                                            userDictionary:nil
                                           sendImmediately:YES];
    [NewRelicAgent startWithApplicationToken:@"AA06ece2f1fe67f34192ff2f3602b18a48f16af3c1"];

    
    MMDrawerController *drawerController=(MMDrawerController*)self.window.rootViewController;
    UINavigationController *navigationController=[drawerController.storyboard instantiateViewControllerWithIdentifier:@"InitialNavigationController"];
    drawerController.centerViewController=navigationController;
    UIViewController *left=[drawerController.storyboard instantiateViewControllerWithIdentifier:@"LeftViewController"];
    [drawerController setLeftDrawerViewController:left];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    
    [GMSServices provideAPIKey:kGoogleAPIKey];
    [FDSupport setUpWithSite:kFreshDeskSite andApikey:kFreshDeskAPIKey];
    [Mixpanel sharedInstanceWithToken:kMixPanelToken];
    [[Mixpanel sharedInstance] registerSuperProperties:@{@"version":@"spotio", @"platform":@"iOS"}];
    [AFNetworkActivityIndicatorManager sharedManager].enabled=YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ICNetFailed:) name:@"ICNetFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:@"ICUserLoggedInn" object:nil];
    //[[ICRequestManager sharedManager] loginUserName:@"romankot3@fake.com" password:@"Asd123" company:@"romankot4" cb:^(BOOL success) {}];
    [Users sharedInstance];
    
    [[UINavigationBar appearance] setTintColor: [UIColor colorWithRed:243/255.0 green:156/255.0 blue:18/255.0 alpha:1.0]];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *)deviceToken {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSString *token=[[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    NSLog(@"%@",token);
    // Make sure identify has been called before sending
    // a device token.
    [mixpanel identify:[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey]];
    // This sends the deviceToken to Mixpanel
    [mixpanel.people addPushDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Show alert for push notifications recevied while the
    // app is running
    NSString *message = [[userInfo objectForKey:@"aps"]
                         objectForKey:@"alert"];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@""
                          message:message
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self startFanout];
}

- (void)startFanout {
    [[FanOut sharedInstance] subscribe:[[NSUserDefaults standardUserDefaults] objectForKey:kCompanyNameKey] realm:kFanOutRealm];
}

- (void)showLoading:(BOOL)yeah {
    NSLog(@"%s:%@",__FUNCTION__,@(yeah));
    if(!yeah){
        [_alert dismissWithClickedButtonIndex:0 animated:YES];
        return;
    }
    self.alert=[[UIAlertView alloc] initWithTitle:nil message:@"Please wait while your pins are downloading, this will only happen once." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [_alert show];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRefreshDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)userLoggedIn:(NSNotification*)notification {
    [self startFanout];
}

- (void)ICNetFailed:(NSNotification*)notification {
    if([notification.userInfo[@"status"] intValue]==401){
        MMDrawerController *drawerController=(MMDrawerController*)self.window.rootViewController;
        [drawerController performSegueWithIdentifier:@"LoginSegue" sender:nil];
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSFetchedResultsController *)fetchResultController
{
    if (_fetchResultController !=nil) {
        return _fetchResultController;
    }
    NSManagedObjectContext* context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Pin" inManagedObjectContext:context]];
    _fetchResultController = [NSFetchedResultsController new];
    [_fetchResultController initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    
    return _fetchResultController;
    
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"pins" withExtension:@"momd"];
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"coredata.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (void)clearStore {
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"coredata.sqlite"];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
