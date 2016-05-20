//
//  VJVitalCapacityController.m
//  VitalCapacityTest
//
//  Created by houweijia on 16/5/20.
//  Copyright © 2016年 VJ. All rights reserved.
//

#import "VJVitalCapacityController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface VJVitalCapacityController ()<AVAudioRecorderDelegate>

{
    //用来录音
    AVAudioRecorder *recorder;
    //设置定时检测，用来监听当前音量大小，控制话筒图片
    NSTimer *timer;
    //设置一个路径，用来保存本地录音的路径
    NSURL *urlPlay;

    UILabel *_numLabel; //肺活量
    int i;
    
    
}

//用来控制录音功能
@property (nonatomic, strong) UIButton *btn;
//用来播放已经录好的音频文件
@property (nonatomic, strong) UIButton *playBtn;
//控制音量的图片
@property (nonatomic, strong) UIImageView *imageView;
//音频播放器
@property (nonatomic, strong) AVAudioPlayer *paly;

@end

@implementation VJVitalCapacityController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //基本步骤：1.进行录音设置（先配置录音机（是一个字典），设置录音的格式，录音的采样率，录音的先行采样位数，录音的通道数，录音质量，录音路径，初始化录音对象，开启音量检测）；2.设置录音按钮的功能（UI设置）3.设置播放按钮并实现播放功能
    //1.进行录音设置
    [self audio];

    
    _numLabel=[[UILabel alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    _numLabel.backgroundColor=[UIColor cyanColor];
    _numLabel.textAlignment=NSTextAlignmentCenter;
    _numLabel.text=@"0";
    [self.view addSubview:_numLabel];
    

    self.btn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btn.frame = CGRectMake(0, 300, self.view.bounds.size.width, 100);
    [self.btn setTitle:@"开始" forState:UIControlStateNormal];
    [self.btn setBackgroundColor:[UIColor cyanColor]];
    [self.btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.btn addTarget:self action:@selector(btnUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btn];
}

//录音设置的方法
- (void)audio{
    
    
    NSError *error = nil;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance]; //得到AVAudioSession单例对象
     [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];//设置类别,表示该应用同时支持播放和录音
      [audioSession setActive:YES error: &error];//启动音频会话管理,此时会阻断后台音乐的播放.
    
    //1.先配置Recorder(录音机)
    NSMutableDictionary *recorderSetting = [NSMutableDictionary dictionary];
    //2.设置录音的格式 / *在2000年被用在MPEG-4中（ISO 14496-3 Audio），所以现在变更为MPEG-4 AAC标准，也就是说，AAC已经成为MPEG4家族的主要成员之一，它是MPEG4第三部分中的音频编码系统。AAC可提供最多48个全音域音频通道。*/
    [recorderSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //3.设置录音采样率 --采样频率是指录音设备在一秒钟内对声音信号的采样次数，采样频率越高声音的还原就越真实越自然。在当今的主流声卡上，采样频率一般共分为22.05KHz、44.1KHz、48KHz三个等级，22.05只能达到FM广播的声音品质，44.1KHz则是理论上的CD音质界限，48KHz则更加精确一些
    [recorderSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //4.设置录音的通道数
    [recorderSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //5.线性采样位数 8 ，16 ，24 ，32、采样位数可以理解为声卡处理声音的解析度。这个数值越大，解析度就越高，录制和回放的声音就越真实 --一般都是16位的（2的16次方）
    /*
    PCM的基本参数是采样频率和采样位深，采样频率就是每秒采样多少次，位深就是声音通过拾音器转成的电平信号被量化的精细度，同时也代表一次采样会用多少位保存
    */
    [recorderSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //6,录音质量
    [recorderSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    [recorderSetting setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsBigEndianKey];
   [recorderSetting setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsFloatKey];
    

    //设置录音路径
    NSString *strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/record.aac",strUrl]];
    
    //记录当前路径
    urlPlay = url;
    
    //初始化录音对象
    NSError *error2;
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recorderSetting error:&error2];
    
    //开启音量检测
    recorder.meteringEnabled = YES;
    recorder.delegate = self;
}



- (void)btnUp:(UIButton *)sender{

    //删除我们的记录文件
    [recorder deleteRecording];
    //停止录音
    [recorder stop];
    //停止计时器
    [timer invalidate];
    
    [self.btn setTitle:@"使劲吹吧" forState:UIControlStateNormal];
    _numLabel.text=@"0";
    i=0;
    
    //创建录音文件，准备录音
    if([recorder prepareToRecord]){
        //开始
        [recorder record];
        
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(detectionVioce) userInfo:nil repeats:YES];
    self.btn.userInteractionEnabled=NO;
}

- (void)detectionVioce
{
    
    [recorder updateMeters];
    float avg = [recorder peakPowerForChannel:1];
    
    //比如把-60作为最低分贝
    float minValue = -60;
    //把60作为获取分配的范围
    float range = 60;
    //把100作为输出分贝范围
    float outRange = 100;
    //确保在最小值范围内
    if (avg < minValue)
    {
        avg = minValue;
    }
    //计算显示分贝
   float decibels = (avg + range) / range * outRange;
//    _label.text=[NSString stringWithFormat:@"%f",decibels];
    
    if (i>100 && decibels <75) {
            //删除我们的记录文件
            [recorder deleteRecording];
            //停止录音
            [recorder stop];
            //停止计时器
            [timer invalidate];
            [self.btn setTitle:@"再测一次" forState:UIControlStateNormal];
        self.btn.userInteractionEnabled=YES;
    }
    else if (80<decibels && decibels<100){
        i+=10;
        _numLabel.text=[NSString stringWithFormat:@"%d",i];

    }
    else if (decibels ==outRange)
    {
    i+=20;
    _numLabel.text=[NSString stringWithFormat:@"%d",i];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
