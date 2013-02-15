//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"

@interface ELCAssetTablePicker ()

@property (nonatomic, strong) NSMutableSet *selectedAssets;

@end

@implementation ELCAssetTablePicker

@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, elcAssets;

- (void)dealloc
{
    [loadingIndicatorView release];
    
    [elcAssets release];
    [selectedAssetsLabel release];
    [super dealloc];
}

- (void)viewDidLoad {
    loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    loadingIndicatorView.color = [UIColor grayColor];
    
    _selectedAssets = [[NSMutableSet alloc] init];
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
	[self.navigationItem setTitle:NSLocalizedString(@"Loading...", @"Loading...")];

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    loadingIndicatorView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [loadingIndicatorView startAnimating];
    [self.view addSubview:loadingIndicatorView];
}

-(void)preparePhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	
    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
     {         
         if(result == nil) 
         {
             return;
         }
         
         ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
         [elcAsset setParent:self];
         [self.elcAssets addObject:elcAsset];
     }];
    NSLog(@"done enumerating photos");
	
    [loadingIndicatorView removeFromSuperview];
    [loadingIndicatorView release];
    loadingIndicatorView = nil;
    
	[self.tableView reloadData];
    // Scroll to bottom
    NSInteger numberOfRows = ceil([self.assetGroup numberOfAssets] / 4.0);
    if (numberOfRows > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:numberOfRows-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
    
	[self.navigationItem setTitle:NSLocalizedString(@"Pick Photos", @"Pick Photos")];
    
    [pool release];

}

- (void) doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for(ELCAsset *elcAsset in self.elcAssets) 
    {		
		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil([self.assetGroup numberOfAssets] / 4.0);
}

- (NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
	int index = (_indexPath.row*4);
	int maxIndex = (_indexPath.row*4+3);
    
	// NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, [assets count]);
    
	if(maxIndex < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				[self.elcAssets objectAtIndex:index+3],
				nil];
	}
    
	else if(maxIndex-1 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				nil];
	}
    
	else if(maxIndex-2 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				nil];
	}
    
	else if(maxIndex-3 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:index]];
	}
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSArray *assets = [self assetsForIndexPath:indexPath];
    if (cell == nil) 
    {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:assets reuseIdentifier:CellIdentifier] autorelease];
    }	
	else 
    {
		[cell setAssets:assets];
	}
    
    // Show to user that assets of different type than the selected ones
    // can't be selected.
    for(ELCAsset *asset in assets) {
        [asset setDisabled:![self canSelectAsset:asset.asset]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;
}

- (BOOL)canSelectAsset:(ALAsset *)asset
{
    ALAsset *lastSelectedAsset = [_selectedAssets anyObject];
    if (lastSelectedAsset && [lastSelectedAsset valueForProperty:ALAssetPropertyType] != [asset valueForProperty:ALAssetPropertyType]) {
        return NO;
    }
    
    return YES;
}

- (void)didDeselectAsset:(ALAsset *)asset
{
    [_selectedAssets removeObject:asset];
    
    if ([_selectedAssets count] == 0) {
        [self.tableView reloadData];
    }
}

- (void)didSelectAsset:(ALAsset *)asset
{
    BOOL firstSelection = [_selectedAssets count] == 0;
    [_selectedAssets addObject:asset];
    if (firstSelection) {
        [self.tableView reloadData];
    }
}

@end
