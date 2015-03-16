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

static const int kStep = 10;
static const int kIterationCount = 50 * kStep;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIView *chartContainerView;

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
                    [_memoryUsageList1 addObject:@(i)];
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
                [_memoryUsageList2 addObject:@(i)];
            }
        }
    });
    
    //Done work
    dispatch_sync(serialQueue, ^{
        NSLog(@"1: %d", _memoryUsageList1.count);
        NSLog(@"2: %d", _memoryUsageList2.count);
        
        DISPATCH_ON_MAIN_THREAD(^{
            _infoLabel.text = @"Done !";
            
            [self showResult];
        })
    });
}

#pragma mark - Chart

- (void)showResult {
    PNLineChart *chartView = [[PNLineChart alloc] initWithFrame:_chartContainerView.bounds];
    
    //With autoreleasepool chart line
    PNLineChartData *lineData1 = [PNLineChartData new];
    lineData1.color = [UIColor greenColor];
    lineData1.itemCount = _memoryUsageList1.count;
    lineData1.getData = ^(NSUInteger index) {
        return [PNLineChartDataItem dataItemWithY:[((NSNumber *)_memoryUsageList1[index]) floatValue]];
    };
    
    //Without autoreleasepool chart line
    PNLineChartData *lineData2 = [PNLineChartData new];
    lineData2.color = [UIColor redColor];
    lineData2.itemCount = _memoryUsageList2.count;
    lineData2.getData = ^(NSUInteger index) {
        return [PNLineChartDataItem dataItemWithY:[((NSNumber *)_memoryUsageList2[index]) floatValue]];
    };
    
    [_chartContainerView addSubview:chartView];
    chartView.chartData = @[lineData1, lineData2];
    [chartView strokeChart];
}

#pragma mark - Memory methods

double report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    double memoryUsageInMB = kerr == KERN_SUCCESS ? (info.resident_size / 1024.0 / 1024.0) : 0.0;
    
    return memoryUsageInMB;
}

@end
