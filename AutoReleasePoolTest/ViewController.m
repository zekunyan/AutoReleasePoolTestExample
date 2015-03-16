//
//  ViewController.m
//  AutoReleasePoolTest
//
//  Created by zorro on 15/3/16.
//  Copyright (c) 2015年 tutuge. All rights reserved.
//

#import "ViewController.h"
#import "PNChart.h"

#import <mach/mach.h>

#define DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(), (mainQueueBlock));
#define GetScreenWidth      [[UIScreen mainScreen] bounds].size.width

static const int kStep = 50000;
static const int kIterationCount = 10 * kStep;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property(strong, nonatomic) NSMutableArray *memoryUsageList1;
@property(strong, nonatomic) NSMutableArray *memoryUsageList2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Init
    _memoryUsageList1 = [NSMutableArray new];
    _memoryUsageList2 = [NSMutableArray new];
}

#pragma mark - Actions

- (IBAction)runTest:(UIButton *)sender {
    //Disable and hide the test button
    sender.enabled = NO;
    [UIView animateWithDuration:0.5f animations:^{
        sender.alpha = 0.1;
    }];
    
    _infoLabel.text = @"Begin testing...";
    
    //Create serial queue to run test.
    dispatch_queue_t serialQueue = dispatch_queue_create("me.tutuge.test.autoreleasepool", DISPATCH_QUEUE_SERIAL);
    
    //Run loop with autoReleasePool
    dispatch_sync(serialQueue, ^{
        for (int i = 0; i < kIterationCount; i++) {
            @autoreleasepool {
                NSNumber *num = [NSNumber numberWithInt:i];
                NSString *str = [NSString stringWithFormat:@"%d ", i];
                
                //Use num and str...whatever...
                [NSString stringWithFormat:@"%@%@", num, str];
                
                if (i % kStep == 0) {
                    [_memoryUsageList1 addObject:@(getMemoryUsage())];
                }
            }
        }
    });
    
    //Run loop without autoReleasePool
    dispatch_sync(serialQueue, ^{
        for (int i = 0; i < kIterationCount; i++) {
            NSNumber *num = [NSNumber numberWithInt:i];
            NSString *str = [NSString stringWithFormat:@"%d ", i];
            
            //Use num and str...whatever...
            [NSString stringWithFormat:@"%@%@", num, str];
            
            if (i % kStep == 0) {
                [_memoryUsageList2 addObject:@(getMemoryUsage())];
            }
        }
    });
    
    //Done work
    dispatch_sync(serialQueue, ^{
        DISPATCH_ON_MAIN_THREAD(^{
            _infoLabel.text = @"Done !";
            
            [self showResult];
        })
    });
}

#pragma mark - Chart

- (void)showResult {
    PNLineChart *chartView = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 60, SCREEN_WIDTH, 320)];
    
    chartView.showCoordinateAxis = YES;
    chartView.yFixedValueMax = 120;
    chartView.yFixedValueMin = 0;
    chartView.yUnit = @"MB";
    
    //With autoreleasepool chart line
    PNLineChartData *lineData1 = [PNLineChartData new];
    lineData1.dataTitle = @"With @autoreleasepool";
    lineData1.color = PNFreshGreen;
    lineData1.alpha = 0.8;
    lineData1.itemCount = _memoryUsageList1.count;
    lineData1.inflexionPointStyle = PNLineChartPointStyleTriangle;
    lineData1.getData = ^(NSUInteger index) {
        return [PNLineChartDataItem dataItemWithY:[((NSNumber *)_memoryUsageList1[index]) floatValue]];
    };
    
    //Without autoreleasepool chart line
    PNLineChartData *lineData2 = [PNLineChartData new];
    lineData2.dataTitle = @"Without @autoreleasepool";
    lineData2.color = PNWeiboColor;
    lineData2.alpha = 0.8;
    lineData2.itemCount = _memoryUsageList2.count;
    lineData2.inflexionPointStyle = PNLineChartPointStyleCircle;
    lineData2.getData = ^(NSUInteger index) {
        return [PNLineChartDataItem dataItemWithY:[((NSNumber *)_memoryUsageList2[index]) floatValue]];
    };
    
    chartView.chartData = @[lineData1, lineData2];
    [chartView strokeChart];
    
    [self.view addSubview:chartView];
    chartView.legendStyle = PNLegendItemStyleSerial;
    chartView.legendFontSize = 12.0f;
    
    UIView *legend = [chartView getLegendWithMaxWidth:SCREEN_WIDTH];
    [legend setFrame:CGRectMake(0, 400, legend.frame.size.width, legend.frame.size.height)];
    [self.view addSubview:legend];
}

#pragma mark - Memory methods

double getMemoryUsage(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    double memoryUsageInMB = kerr == KERN_SUCCESS ? (info.resident_size / 1024.0 / 1024.0) : 0.0;
    
    return memoryUsageInMB;
}

@end
