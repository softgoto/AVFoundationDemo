//
//  ViewController.m
//  AVFoundation_Test
//
//  Created by xuhui on 16/2/25.
//  Copyright © 2016年 softgoto. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    AVAudioRecorder *_audioRecorder;
    AVAudioSession *_audioSession;
    AVAudioPlayer *_audioPlayer;
    
    NSURL *_recordUrl;
    
    NSTimer *_timer;
    int _count;
    int _playDuration;
    UILabel *_timeLab;
    UILabel *_fileSize;
    UIButton *_start;
    UIButton *_stop;
    
    UIButton *_play;
    
    BOOL _recordPermission;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _count = 0;
    
    _timeLab = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-100, 200, 200, 40)];
    _timeLab.text = @"0";
    _timeLab.font = [UIFont systemFontOfSize:14];
    _timeLab.textColor = [UIColor orangeColor];
    _timeLab.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_timeLab];
    
    _start = [UIButton buttonWithType:UIButtonTypeCustom];
    _start.frame = CGRectMake(self.view.frame.size.width/2.0-100, 300, 200, 40);
    [_start setTitle:@"Start Record" forState:UIControlStateNormal];
    _start.backgroundColor = [UIColor orangeColor];
    [_start addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_start];
    
    _stop = [UIButton buttonWithType:UIButtonTypeCustom];
    _stop.frame = CGRectMake(self.view.frame.size.width/2.0-100, 420, 200, 40);
    [_stop setTitle:@"Stop Record" forState:UIControlStateNormal];
//    _stop.backgroundColor = [UIColor orangeColor];
    [_stop addTarget:self action:@selector(stopRecord:) forControlEvents:UIControlEventTouchUpInside];
    _stop.backgroundColor = [UIColor grayColor];
    _stop.userInteractionEnabled = NO;
    [self.view addSubview:_stop];
    
    _fileSize = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-100, 480, 200, 40)];
    _fileSize.font = [UIFont systemFontOfSize:14];
    _fileSize.textAlignment = NSTextAlignmentCenter;
    _fileSize.textColor = [UIColor orangeColor];
    [self.view addSubview:_fileSize];
    
    _play = [UIButton buttonWithType:UIButtonTypeCustom];
    _play.frame = CGRectMake(self.view.frame.size.width/2.0-100, 540, 200, 40);
    [_play setTitle:@"Play Record" forState:UIControlStateNormal];
    [_play addTarget:self action:@selector(playRecord:) forControlEvents:UIControlEventTouchUpInside];
    _play.backgroundColor = [UIColor grayColor];
    _play.userInteractionEnabled = NO;
    [self.view addSubview:_play];
    
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）, 采样率必须要设为11025才能使转化成mp3格式后不会失真
    [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
    //录音通道数  1 或 2 ，要转换成mp3格式必须为双通道
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:8] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    //存储录音文件
    _recordUrl = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"selfRecord.caf"]];
    
    //初始化
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:_recordUrl settings:recordSetting error:nil];
    //开启音量检测
    _audioRecorder.meteringEnabled = YES;
    _audioRecorder.delegate = self;

    
    [self checkRecordPermission];
}


#pragma mark - Start
- (void)startRecord:(id)sender
{
    [self checkRecordPermission];
    
    if (!_recordPermission) {
        return;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    _timeLab.text = @"0";
    _fileSize.text = @"";
    
    _audioSession = [AVAudioSession sharedInstance];//得到AVAudioSession单例对象
    
    if (![_audioRecorder isRecording]) {
        [_audioSession setCategory:AVAudioSessionCategoryRecord error:nil];//设置类别,表示该应用同时支持播放和录音
        [_audioSession setActive:YES error:nil];//启动音频会话管理,此时会阻断后台音乐的播放.
        
        [_audioRecorder prepareToRecord];
        [_audioRecorder peakPowerForChannel:0.0];
        [_audioRecorder record];
        
    }
    
    _start.backgroundColor = [UIColor grayColor];
    _start.userInteractionEnabled = NO;
    
    _stop.backgroundColor = [UIColor orangeColor];
    _stop.userInteractionEnabled = YES;
    
    _play.backgroundColor = [UIColor grayColor];
    _play.userInteractionEnabled = NO;
}

#pragma mark - Stop
- (void)stopRecord:(id)sender
{
    [_audioRecorder stop];                          //录音停止
    [_audioSession setActive:NO error:nil];         //一定要在录音停止以后再关闭音频会话管理（否则会报错），此时会延续后台音乐播放
    [_timer invalidate];                            //timer失效

    NSLog(@"%@", _recordUrl);
    
    NSString *size = [self stringWithFileSize:[self fileSizeAtPath:_recordUrl.absoluteString]];
    _fileSize.text = size;
    NSLog(@"%@", size);
    
    
    _start.backgroundColor = [UIColor orangeColor];
    _start.userInteractionEnabled = YES;
    
    _stop.backgroundColor = [UIColor grayColor];
    _stop.userInteractionEnabled = NO;
    
    _play.backgroundColor = [UIColor orangeColor];
    _play.userInteractionEnabled = YES;
}

#pragma mark - Play
- (void)playRecord:(id)sender
{
    _start.backgroundColor = [UIColor grayColor];
    _start.userInteractionEnabled = NO;
    
    _play.backgroundColor = [UIColor grayColor];
    _play.userInteractionEnabled = NO;
    
    
    [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [_audioSession setActive:YES error:nil];
    
    if (_recordUrl != nil){
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_recordUrl error:nil];
        _audioPlayer.delegate = self;
    }
    
    [_audioPlayer prepareToPlay];
    _audioPlayer.volume = 1;
    [_audioPlayer play];
    
    _playDuration = (int)_audioPlayer.duration;
    [_play setTitle:[NSString stringWithFormat:@"%d", _playDuration] forState:UIControlStateNormal];
    NSLog(@"音频时长为：%d", _playDuration);
    
    //播放倒计时
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playTimeTick) userInfo:nil repeats:YES];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _start.backgroundColor = [UIColor orangeColor];
    _start.userInteractionEnabled = YES;
    
    [_timer invalidate];
    
    [_play setTitle:@"Play Record" forState:UIControlStateNormal];
    
    [player stop];
    [_audioSession setActive:NO error:nil];
}

#pragma mark - Timer
- (void)updateTimer:(id)sender
{
    _count ++;
    _timeLab.text = [NSString stringWithFormat:@"%d", _count];
}

- (void)playTimeTick
{
    _playDuration --;
    [_play setTitle:[NSString stringWithFormat:@"%d", _playDuration] forState:UIControlStateNormal];
}

#pragma mark - Private
- (long long)fileSizeAtPath:(NSString*) filePath{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:filePath]){
        
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (NSString *)stringWithFileSize:(CGFloat)size {
    CGFloat newSize = size;
    NSString* unit = @"B";
    if(size > 1000 * 1024 * 1024) {
        newSize = size / (1024.0f * 1024.0f * 1024.0f);
        unit = @"GB";
    } else if(size > 1000 * 1024) {
        newSize = size / (1024.0f * 1024.0f);
        unit = @"MB";
    } else if(size > 100) {
        newSize = size / 1024.0f;
        unit = @"KB";
    }
    
    newSize = (int) (newSize * 10.0f) / 10.0f;
    return [NSString stringWithFormat:@"%g%@", newSize, unit];
}

//检查权限
- (void)checkRecordPermission
{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                // Microphone enabled code
                NSLog(@"Microphone is enabled..");
                _recordPermission = YES;
            } else {
                // Microphone disabled code
                NSLog(@"Microphone is disabled..");
                _recordPermission = NO;
                // We're in a background thread here, so jump to main thread to do UI work.
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Microphone Access Denied" message:@"This app requires access to your device's Microphone.\n\nPlease enable Microphone access for this app in Settings / Privacy / Microphone" preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:@"Dissmiss" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                });
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
