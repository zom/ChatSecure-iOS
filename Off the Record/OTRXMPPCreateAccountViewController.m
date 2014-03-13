//
//  OTRXMPPCreateViewController.m
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountViewController.h"
#import "Strings.h"

#import "HITorManager.h"
#import "OTRAccountsManager.h"
#import "OTRLog.h"

@interface OTRXMPPCreateAccountViewController ()

@property (nonatomic,strong) NSArray * hostnameArray;

@property (nonatomic) BOOL wasAbleToCreateAccount;

@end

@implementation OTRXMPPCreateAccountViewController

- (id)initWithHostnames:(NSArray *)newHostnames
{
    self = [super init];
    if (self) {
        self.hostnameArray = newHostnames;
        self.selectedHostname = [self.hostnameArray firstObject];
    }
    return self;
}

#pragma - mark View Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = CREATE_NEW_ACCOUNT_STRING;
	self.usernameTextField.placeholder = USERNAME_STRING;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    self.loginButton.title = CREATE_STRING;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.wasAbleToCreateAccount = NO;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRegistrationSucceededNotification:)
     name:OTRXMPPRegisterSucceededNotificationName
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRegistrationFailedNotification:)
     name:OTRXMPPRegisterFailedNotificationName
     object:nil ];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:OTRXMPPRegisterFailedNotificationName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:OTRXMPPRegisterSucceededNotificationName
                                                  object:nil];
    if (!self.wasAbleToCreateAccount) {
        [OTRAccountsManager removeAccount:self.account];
    }
}

#pragma - mark UITableViewDelegate Mehtods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.hostnameArray.count) {
        return 2;
    }
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return self.hostnameArray.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return HOSTNAME_STRING;
    }
    return BASIC_STRING;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return 44.0f;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const domainCellIdentifier = @"domainCellIdentifer";
    UITableViewCell * cell = nil;
    if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:domainCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:domainCellIdentifier];
        }
        NSString * hostName = self.hostnameArray[indexPath.row];
        cell.textLabel.text = hostName;
        if ([hostName isEqualToString:self.selectedHostname]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        self.selectedHostname = self.hostnameArray[indexPath.row];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void) loginButtonPressed:(id)sender
{
    self.loginButtonPressed = YES;
    if(self.isTorAccount && ![HITorManager defaultManager].isRunning)
    {
        [self showHUDWithText:CONNECTING_TO_TOR_STRING];
        [[HITorManager defaultManager] start];
    }
    else {
        self.account.username = self.usernameTextField.text;
        self.account.domain = self.selectedHostname;
        self.account.rememberPasswordValue = self.rememberPasswordSwitch.on;
        self.account.autologinValue = self.autoLoginSwitch.on;
        OTRXMPPManager * xmppManager = [self xmppManager];
        if (xmppManager) {
            [self showHUDWithText:CREATING_ACCOUNT_STRING];
            [xmppManager registerNewAccountWithPassword:self.passwordTextField.text];
        }
    }
}

- (void)didReceiveRegistrationSucceededNotification:(NSNotification *)notification
{
    self.wasAbleToCreateAccount = YES;
    OTRXMPPManager * xmppMananger = [self xmppManager];
    if (xmppMananger) {
        self.HUD.labelText = LOGGING_IN_STRING;
        [xmppMananger connectWithPassword:self.passwordTextField.text];
    }
}

- (void)didReceiveRegistrationFailedNotification:(NSNotification *)notification
{
    [self hideHUD];
    self.wasAbleToCreateAccount = NO;
    NSError * error = [[notification userInfo] objectForKey:kOTRNotificationErrorKey];
    DDLogWarn(@"Registration Failed: %@",error);
    NSString * errorString = REGISTER_ERROR_STRING;
    if (error) {
        if ([error.domain isEqualToString:OTRXMPPErrorDomain]) {
            if (error.code == OTRXMPPUnsupportedAction) {
                errorString = IN_BAND_ERROR_STRING;
            }
            else if (error.code == OTRXMPPXMLError) {
                if ([error.localizedDescription length]) {
                    errorString = error.localizedDescription;
                }
            }
        }
    }
    
    [self showAlertViewWithTitle:ERROR_STRING message:errorString error:error];
}

- (OTRXMPPManager *)xmppManager
{
    id protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
    OTRXMPPManager * xmppManager = nil;
    if ([protocol isKindOfClass:[OTRXMPPManager class]]) {
        xmppManager = (OTRXMPPManager *)protocol;
    }
    return xmppManager;
}

+ (instancetype)createViewControllerWithHostnames:(NSArray *)hostNames
{
    return [[self alloc] initWithHostnames:hostNames];
}

@end
