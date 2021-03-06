//
//  ZCSAvatarCaptureController.m
//  ZCSAvatarCaptureDemo
//
//  Created by Zane Shannon on 8/27/14.
//  Copyright (c) 2014 Zane Shannon. All rights reserved.
//

#import "ZCSAvatarCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ZCSAvatarCaptureController () {
	CGRect previousFrame;
	BOOL isCapturing;
}

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIView *captureView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign) BOOL isCapturingImage;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIView *imageSelectedView;
@property (nonatomic, strong) UIImage *selectedImage;

- (void)endCapture;

@end

@implementation ZCSAvatarCaptureController

- (void)viewDidLoad {
	[super viewDidLoad];
	isCapturing = NO;
	UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startCapture)];
	[self.view addGestureRecognizer:singleTapGestureRecognizer];
	self.avatarView = [[UIImageView alloc] init];
	self.avatarView.image = self.image;
	[self.view addSubview:self.avatarView];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	self.view.frame = self.view.superview.bounds;
}

- (void)viewDidLayoutSubviews {
    [self startCapture];
}

- (void)startCapture {
	if (isCapturing) return;
	isCapturing = YES;
	for (UIView *subview in [self.view.subviews copy]) {
		[subview removeFromSuperview];
	}
	previousFrame = [self.view convertRect:self.view.frame toView:nil];
	
	self.captureView = [[UIView alloc] initWithFrame:self.view.frame];
	[self.view addSubview:self.captureView];
	
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;

	self.capturedImageView = [[UIImageView alloc] init];
    self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
	self.capturedImageView.frame = previousFrame;
	self.capturedImageView.userInteractionEnabled = YES;

	self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	self.captureVideoPreviewLayer.frame = previousFrame;
	[self.captureView.layer addSublayer:self.captureVideoPreviewLayer];

	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	if (devices.count > 0) {
        self.captureDevice = devices[0];
		for (AVCaptureDevice *device in devices) {
			if (device.position == AVCaptureDevicePositionBack) {
				self.captureDevice = device;
				break;
			}
		}

		NSError *error = nil;
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];

		[self.captureSession addInput:input];

		self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
		[self.stillImageOutput setOutputSettings:outputSettings];
		[self.captureSession addOutput:self.stillImageOutput];
		
		UIButton *shutterButton = [[UIButton alloc] initWithFrame:CGRectMake(
            previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 50,
            previousFrame.origin.y + CGRectGetHeight(previousFrame) - 110,
            100, 100
         )];
		[shutterButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/take-snap"] forState:UIControlStateNormal];
		[shutterButton addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
		[shutterButton.layer setCornerRadius:20.0];
		[self.captureView addSubview:shutterButton];

		UIButton *swapCamerasButton = [[UIButton alloc] initWithFrame:CGRectMake(
            previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) + 70,
            previousFrame.origin.y + CGRectGetHeight(previousFrame) - 70,
            47, 25
        )];
		[swapCamerasButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/front-camera"] forState:UIControlStateNormal];
		[swapCamerasButton addTarget:self action:@selector(swapCameras:) forControlEvents:UIControlEventTouchUpInside];
		[self.captureView addSubview:swapCamerasButton];
	}

	UIButton *showImagePickerButton = [[UIButton alloc] initWithFrame:CGRectMake(
        previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 100,
        previousFrame.origin.y + CGRectGetHeight(previousFrame) - 70,
        27, 27
    )];
	[showImagePickerButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/library"] forState:UIControlStateNormal];
	[showImagePickerButton addTarget:self action:@selector(showImagePicker:) forControlEvents:UIControlEventTouchUpInside];
	[self.captureView addSubview:showImagePickerButton];


	self.imageSelectedView = [[UIView alloc] initWithFrame:self.captureView.frame];
	[self.imageSelectedView addSubview:self.capturedImageView];
    
    UIButton *selectPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(
        previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 16 - 50,
        previousFrame.origin.y + CGRectGetHeight(previousFrame) - 70,
        32, 32
    )];
	[selectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/selected"] forState:UIControlStateNormal];
	[selectPhotoButton addTarget:self action:@selector(photoSelected:) forControlEvents:UIControlEventTouchUpInside];
	[self.imageSelectedView addSubview:selectPhotoButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(
        previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 16 + 50,
        previousFrame.origin.y + CGRectGetHeight(previousFrame) - 70,
        32, 32
    )];
    [cancelButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelSelectedPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageSelectedView addSubview:cancelButton];

	[self.captureSession startRunning];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)endCapture {
	[self.captureSession stopRunning];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	[self.captureVideoPreviewLayer removeFromSuperlayer];
	for (UIView *subview in [self.captureView.subviews copy]) {
		[subview removeFromSuperview];
	}
    self.avatarView = [[UIImageView alloc] init];
	self.avatarView.image = self.image;
	[self.view addSubview:self.avatarView];
	[self.captureView removeFromSuperview];
	isCapturing = NO;
}

- (IBAction)capturePhoto:(id)sender {
	self.isCapturingImage = YES;
	bool isFrontFacing = self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
			break;
		}
	}

	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
							   completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {

								   if (imageSampleBuffer != NULL) {

									   NSData *imageData = [AVCaptureStillImageOutput
										   jpegStillImageNSDataRepresentation:imageSampleBuffer];
									   UIImage *capturedImage = [[UIImage alloc] initWithData:imageData scale:1];
									   
									   if (isFrontFacing) {
										   capturedImage = [UIImage imageWithCGImage:capturedImage.CGImage
															   scale:capturedImage.scale
														 orientation:UIImageOrientationLeftMirrored];
									   }
									   
									   self.isCapturingImage = NO;
									   self.capturedImageView.image = capturedImage;
									   for (UIView *view in self.captureView.subviews) {
										   if ([view class] == [UIButton class]) view.hidden = YES;
									   }
									   [self.captureView addSubview:self.imageSelectedView];
									   self.selectedImage = capturedImage;
									   imageData = nil;
								   }
							   }];
}

- (IBAction)swapCameras:(id)sender {
	if (self.isCapturingImage != YES) {
		if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
			// rear active, switch to front
			self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];

			[self.captureSession beginConfiguration];
			AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
			for (AVCaptureInput *oldInput in self.captureSession.inputs) {
				[self.captureSession removeInput:oldInput];
			}
			[self.captureSession addInput:newInput];
			[self.captureSession commitConfiguration];
		} else if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
			// front active, switch to rear
			self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
			[self.captureSession beginConfiguration];
			AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
			for (AVCaptureInput *oldInput in self.captureSession.inputs) {
				[self.captureSession removeInput:oldInput];
			}
			[self.captureSession addInput:newInput];
			[self.captureSession commitConfiguration];
		}

		// Need to reset flash btn
	}
}

- (IBAction)showImagePicker:(id)sender {
	self.picker = [[UIImagePickerController alloc] init];
	self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	self.picker.delegate = self;
	[self presentViewController:self.picker animated:YES completion:nil];
}

- (IBAction)photoSelected:(id)sender {
	self.image = self.selectedImage;
	[self endCapture];
	if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
		[self.delegate imageSelected:self.image];
	}
}

- (IBAction)cancelSelectedPhoto:(id)sender {
	[self.imageSelectedView removeFromSuperview];
	for (UIView *view in self.captureView.subviews) {
		if ([view class] == [UIButton class]) view.hidden = NO;
	}
}

- (IBAction)cancel:(id)sender {
	[self endCapture];
	if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
		[self.delegate imageSelectionCancelled];
	}
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	self.selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];

	[self dismissViewControllerAnimated:YES
				   completion:^{
					   self.capturedImageView.image = self.selectedImage;
					   for (UIView *view in self.captureView.subviews) {
						   if ([view class] == [UIButton class]) view.hidden = YES;
					   }
					   [self.captureView addSubview:self.imageSelectedView];
				   }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
