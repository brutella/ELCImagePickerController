//
//  AssetTablePicker.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ELCAssetTablePicker : UITableViewController
{
	ALAssetsGroup *assetGroup;
	
	NSMutableArray *elcAssets;
	
	id parent;
	
	NSOperationQueue *queue;
    UIActivityIndicatorView *loadingIndicatorView;
}
@property (nonatomic, assign) id parent;
@property (nonatomic, assign) ALAssetsGroup *assetGroup;
@property (nonatomic, retain) NSMutableArray *elcAssets;
@property (nonatomic, retain) IBOutlet UILabel *selectedAssetsLabel;

-(int)totalSelectedAssets;
-(void)preparePhotos;
-(void)doneAction:(id)sender;
- (BOOL)canSelectAsset:(ALAsset *)asset;
- (void)didDeselectAsset:(ALAsset *)asset;
- (void)didSelectAsset:(ALAsset *)asset;

@end