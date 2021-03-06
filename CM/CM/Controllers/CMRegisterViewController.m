//
//  CMRegisterViewController.m
//  CM
//
//  Created by Duke on 3/3/16.
//  Copyright © 2016 DU. All rights reserved.
//

#import "CMRegisterViewController.h"
#import "CMRegisterViewModel.h"
#import "CMModel.h"
#import "CMPostProfileViewController.h"



@interface CMRegisterViewController ()

@property(nonatomic,strong,readwrite)CMRegisterViewModel *viewModel;

@property (weak, nonatomic) IBOutlet UITextField *phoneNumTF;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UITextField *rePasswrodTF;
@property (weak, nonatomic) IBOutlet UIButton *reSendButton;
@property (weak, nonatomic) IBOutlet UIButton *goRegisterButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewwidth;

@property (nonatomic,assign) int leftTime;
@end

@implementation CMRegisterViewController
@dynamic viewModel;

- (void)awakeFromNib {
    self.viewModel  = [[CMRegisterViewModel alloc] initWithServices:nil params:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self.reSendButton setTitle:@"发送验证码" forState:UIControlStateDisabled];
    [self.reSendButton setTitle:@"发送验证码" forState:UIControlStateNormal];
    self.scrollViewwidth.constant = SCREEN_WIDTH;
}

- (void)bindViewModel {
    [super bindViewModel];
    RAC(self.viewModel,phoneNum) = self.phoneNumTF.rac_textSignal;
    RAC(self.viewModel,verifyCode) = self.verifyCodeTF.rac_textSignal;
    RAC(self.viewModel,password) = self.passwordTF.rac_textSignal;
    RAC(self.viewModel,rePassword) = self.rePasswrodTF.rac_textSignal;
    
//    [[self.reSendButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        [self performSegueWithIdentifier:@"iRegister" sender:nil];
//    }];
    self.reSendButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        if (self.viewModel.phoneNum.length != 11) {
            NSDictionary *userinfo = @{NSLocalizedFailureReasonErrorKey:@"请输入正确的手机号"                                                                                                              };
            return [RACSignal error:[NSError errorWithDomain:@"" code:0 userInfo:userinfo]];
        }
        else  {
            return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [[self.viewModel.getVerifyCodeCommand execute:@"1"] subscribeNext:^(CMModel *x) {
                    if (x.success) {
                        self.leftTime = 90;
                        self.reSendButton.enabled = NO;
                        [[[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] take:self.leftTime] subscribeNext:^(id x) {
                            self.leftTime --;
                            [self.reSendButton setTitle:[NSString stringWithFormat:@"%d秒后重发",self.leftTime] forState:UIControlStateNormal];
                            if (self.leftTime == 0) {
                                self.reSendButton.enabled = YES;
                                [self.reSendButton setTitle:@"发送验证码" forState:UIControlStateNormal];
                                [subscriber sendNext:@(YES)];
                                [subscriber sendCompleted];
                            }
                        }];
                    }
                    else {
                        NSDictionary *userinfo = @{NSLocalizedFailureReasonErrorKey:x.msg                                                                                                              };
                        [subscriber sendError:[NSError errorWithDomain:@"" code:0 userInfo:userinfo]];
                    }
                    
                }];
                return nil;
            }];

        }
            }];
    [self.reSendButton.rac_command.errors subscribe:self.viewModel.errors];
    
    
    
    @weakify(self)
    [self.viewModel.getVerifyCodeCommand.executing
     subscribeNext:^(NSNumber *executing) {
         @strongify(self)
         if (executing.boolValue) {
             [self.view endEditing:YES];
             [SVProgressHUD showWithStatus:@"请稍后..."];
         } else {
             [SVProgressHUD dismiss];
         }
     }];
    [self.viewModel.getVerifyCodeCommand.errors subscribe:self.viewModel.errors];
    [self.viewModel.getVerifyCodeCommand.errors subscribeNext:^(id x) {
        self.reSendButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            if (self.viewModel.phoneNum.length != 11) {
                NSDictionary *userinfo = @{NSLocalizedFailureReasonErrorKey:@"请输入正确的手机号"                                                                                                              };
                return [RACSignal error:[NSError errorWithDomain:@"" code:0 userInfo:userinfo]];
            }
            else  {
                return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                    [[self.viewModel.getVerifyCodeCommand execute:@"1"] subscribeNext:^(CMModel *x) {
                        if (x.success) {
                            self.leftTime = 90;
                            self.reSendButton.enabled = NO;
                            [[[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] take:self.leftTime] subscribeNext:^(id x) {
                                self.leftTime --;
                                [self.reSendButton setTitle:[NSString stringWithFormat:@"%d秒后重发",self.leftTime] forState:UIControlStateNormal];
                                if (self.leftTime == 0) {
                                    self.reSendButton.enabled = YES;
                                    [self.reSendButton setTitle:@"发送验证码" forState:UIControlStateNormal];
                                    [subscriber sendNext:@(YES)];
                                    [subscriber sendCompleted];
                                }
                            }];
                        }
                        else {
                            NSDictionary *userinfo = @{NSLocalizedFailureReasonErrorKey:x.msg                                                                                                              };
                            [subscriber sendError:[NSError errorWithDomain:@"" code:0 userInfo:userinfo]];
                        }
                        
                    }];
                    return nil;
                }];
                
            }
        }];
        [self.reSendButton.rac_command.errors subscribe:self.viewModel.errors];
    }];
    
    [[self.goRegisterButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        [self performSegueWithIdentifier:@"iProfile" sender:nil];
        [self myresignFirstResponder];
        [[self.viewModel.validRegisterCommand execute:nil] subscribeNext:^(id x) {
            if (x) {
                [self.viewModel.registerCommand execute:nil];
            }
        }];
    }];
    //注册中...
    [self.viewModel.registerCommand.executing
     subscribeNext:^(NSNumber *executing) {
         @strongify(self)
         if (executing.boolValue) {
             [self.view endEditing:YES];
             [SVProgressHUD showWithStatus:@"注册中..."];
         } else {
             [SVProgressHUD dismiss];
         }
     }];
    
    //注册信号返回
    [[self.viewModel.registerCommand.executionSignals switchToLatest]
     subscribeNext:^(CMLoginModel *model) {
         if (model.success) {
             [TSMessage showNotificationInViewController:self.navigationController
                                                subtitle:@"注册成功"
                                                    type:TSMessageNotificationTypeSuccess];
             
//             SSKeychain setAccessToken:model.
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(),^{
                 [self performSegueWithIdentifier:@"iProfile" sender:model.data.accessToken];
             });
         }
         
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"iProfile"]) {
        NSString *accessToken = (NSString *)sender;
        CMPostProfileViewController *vc = segue.destinationViewController;
        vc.viewModel.accessToken = accessToken;
    }
}

-(void)myresignFirstResponder {
    [self.phoneNumTF resignFirstResponder];
    [self.verifyCodeTF resignFirstResponder];
    [self.passwordTF resignFirstResponder];
    [self.rePasswrodTF resignFirstResponder];
}


@end
