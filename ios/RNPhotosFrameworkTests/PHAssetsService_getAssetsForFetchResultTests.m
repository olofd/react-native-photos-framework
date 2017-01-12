#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

#import <XCTest/XCTest.h>
#import "PHAssetsService.h"
#import "RNPFHelpers.h"

@interface PHAssetsServicegetAssetsForFetchResultTests : XCTestCase
@end

@implementation PHAssetsServicegetAssetsForFetchResultTests
NSMutableArray *arrayWithFakeAssets;
NSMutableArray *scenarioAssets;


- (void)setUp {
    arrayWithFakeAssets = [NSMutableArray new];
    for(int i = 0; i < 200;i++){
        [arrayWithFakeAssets addObject:@(i)];
    }
    
    scenarioAssets = [NSMutableArray new];
    [scenarioAssets addObject:@(2012)];
    [scenarioAssets addObject:@(2013)];
    [scenarioAssets addObject:@(2014)];
    [scenarioAssets addObject:@(2015)];
    [scenarioAssets addObject:@(2016)];

    [super setUp];
}

- (void)tearDown {
    arrayWithFakeAssets = nil;
    scenarioAssets = nil;
    [super tearDown];
}

- (void)testLoad {
    


}

- (void)testShouldReturnEqualAmountOfAssets {
    NSArray *resultYesYes = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:YES];
    [self setUp];
    NSArray *resultYesNo = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    [self setUp];
    NSArray *resultNoYes = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    [self setUp];
    NSArray *resultNoNo = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    XCTAssertTrue(resultYesYes.count == 10);
    XCTAssertTrue(resultYesNo.count == 10);
    XCTAssertTrue(resultNoYes.count == 10);
    XCTAssertTrue(resultNoNo.count == 10);
}

-(int) assetAsInt:(PHAssetWithCollectionIndex *)assetWithIndex{
    return [(NSNumber *)[assetWithIndex asset] intValue];
}

//Testing scenarios from : https://github.com/olofd/react-native-photos-framework/pull/11#issuecomment-264324873
-(void) testOrderScenarioOne {
    // load assets from newest to oldest from the top to bottom of screen
    // this is default behavior
    NSArray <PHAssetWithCollectionIndex *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:NO];
    
    XCTAssertEqual(result.count, 3);
    
    XCTAssertEqual([self assetAsInt:result[0]], 2016);
    XCTAssertEqual([self assetAsInt:result[1]], 2015);
    XCTAssertEqual([self assetAsInt:result[2]], 2014);
    //scrolling down will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:NO];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([self assetAsInt:result[0]], 2013);
    XCTAssertEqual([self assetAsInt:result[1]], 2012);
}

-(void) testOrderScenarioTwo {
    // load assets from newest to oldest from the bottom to top of screen
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([self assetAsInt:result[0]], 2014);
    XCTAssertEqual([self assetAsInt:result[1]], 2015);
    XCTAssertEqual([self assetAsInt:result[2]], 2016);
    //scrolling down will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([self assetAsInt:result[0]], 2012);
    XCTAssertEqual([self assetAsInt:result[1]], 2013);
}

-(void) testOrderScenarioThree {
    // load assets from oldest to newest from the top to bottom of screen
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([self assetAsInt:result[0]], 2012);
    XCTAssertEqual([self assetAsInt:result[1]], 2013);
    XCTAssertEqual([self assetAsInt:result[2]], 2014);
    //scrolling up will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([self assetAsInt:result[0]], 2015);
    XCTAssertEqual([self assetAsInt:result[1]], 2016);
}

-(void) testOrderScenarioFour {
    // load assets from oldest to newest from the bottom to top of screen
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:YES];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([self assetAsInt:result[0]], 2014);
    XCTAssertEqual([self assetAsInt:result[1]], 2013);
    XCTAssertEqual([self assetAsInt:result[2]], 2012);
    //scrolling up will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([self assetAsInt:result[0]], 2016);
    XCTAssertEqual([self assetAsInt:result[1]], 2015);
}

@end
