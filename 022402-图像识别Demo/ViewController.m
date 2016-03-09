//
//  ViewController.m
//  0224-OCRImageDmeo
//
//  Created by 刘涛 on 16/2/24.
//  Copyright © 2016年 huanyu. All rights reserved.
//

#import "ViewController.h"
#import "TesseractOCR/TesseractOCR.h"
#import "SVProgressHUD.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<G8TesseractDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (weak, nonatomic) IBOutlet UITextView *showText;

@property (weak, nonatomic) IBOutlet UIImageView *imageToRecognize;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomCon;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCon;

@property (copy, nonatomic) NSString *Language;

@property (weak, nonatomic) IBOutlet UIButton *chiBtn;

@property (weak, nonatomic) IBOutlet UIButton *engBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /// 注册键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self chinese:self.chiBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardChanged:(NSNotification *)note {
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = rect.origin.y - [UIScreen mainScreen].bounds.size.height;
    
    self.topCon.constant = height;
    self.bottomCon.constant = -height;
    [self.view layoutIfNeeded];
    
}

- (IBAction)chooseImage:(id)sender {
    [self addPhoto];
}


- (IBAction)openCamera:(id)sender {
    [self shootPhoto];
}

- (IBAction)recognImage:(id)sender {
    if (self.imageToRecognize.image != nil) {
        [self recognizeImageWithTesseract:self.imageToRecognize.image];
    }
    
}


- (IBAction)chinese:(UIButton *)sender {
    self.chiBtn.selected = YES;
    self.engBtn.selected = NO;
    self.Language = @"chi_sim";
}


- (IBAction)english:(UIButton *)sender {
    self.engBtn.selected = YES;
    self.chiBtn.selected = NO;
    self.Language = @"eng";
}


-(void)recognizeImageWithTesseract:(UIImage *)image
{
    [SVProgressHUD showWithStatus:@"请稍候..."];
    
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:self.Language];
    
    
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    

    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    

    operation.delegate = self;
    
    
    operation.tesseract.image = image;
    

    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        
        NSString *recognizedText = tesseract.recognizedText;
        
        NSLog(@"%@", recognizedText);
        
        [SVProgressHUD dismiss];
        
        self.showText.text = recognizedText;
        
        if ([self.showText.text isEqualToString:@""]) {
            [SVProgressHUD showErrorWithStatus:@"不能识别"];
        }
    };
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        self.imageToRecognize.contentMode = UIViewContentModeScaleAspectFit;
//        self.imageToRecognize.image = operation.tesseract.thresholdedImage;;
//    });
    
    [self.operationQueue addOperation:operation];
}

#pragma mark - 选择图片
// 选择图片
- (void)addPhoto
{
    // 创建图片选择器
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    picker.delegate = self;
    // 显示图片选择器
    [self presentViewController:picker animated:YES completion:nil];
}

///UIImagePickerControllerDelegate方法
// 选择完图片之后调用
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1.取出选中的图片
    UIImage *imageP = info[UIImagePickerControllerEditedImage];
    UIImage *image = [self OriginImage:imageP scaleToWidth:1000];
    if (image != nil) {
       [self recognizeImageWithTesseract:image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.imageToRecognize.contentMode = UIViewContentModeScaleAspectFit;
            self.imageToRecognize.image = image;
        });
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}
// 取消选择会调用
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 拍摄
- (void)shootPhoto {
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        
        UIAlertView *photoAlert = [[UIAlertView alloc] initWithTitle:@"相机不可用" message:@"请到“设置->隐私->相机->OCRImageDmeo”中开启权限" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [photoAlert show];
        return;
    }
    
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = YES;
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
    
}

// 改变图片质量
-(UIImage *) OriginImage:(UIImage *)image scaleToWidth:(CGFloat)width
{
    CGFloat scale = image.size.height / image.size.width;
    CGSize size = CGSizeMake(width, width *scale);
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}


- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}


- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to cancel recognition prematurely
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


#pragma mark - 懒加载
- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}

@end
