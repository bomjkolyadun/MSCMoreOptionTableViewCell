//
//  MSCMoreOptionTableViewCell.m
//  MSCMoreOptionTableViewCell
//
//  Created by Manfred Scheiner (@scheinem) on 20.08.13.
//  Copyright (c) 2013 Manfred Scheiner (@scheinem). All rights reserved.
//

#import "MSCMoreOptionTableViewCell.h"

typedef struct
{
    unsigned moreOptionButtonPressedInRowAtIndexPath : 1;
    unsigned titleForMoreOptionButtonForRowAtIndexPath : 1;
    unsigned imageForMoreOptionButtonForRowAtIndexPath : 1;
    unsigned titleColorForMoreOptionButtonForRowAtIndexPath : 1;
    unsigned backgroundColorForMoreOptionButtonForRowAtIndexPath : 1;
    unsigned backgroundColorForDeleteConfirmationButtonForRowAtIndexPath : 1;
    unsigned imageForDeleteConfirmationButtonForRowAtIndexPath : 1;
    unsigned titleColorForDeleteConfirmationButtonForRowAtIndexPath : 1;
} MSCMoreOptionTableViewCellDelegateAbilities;

@interface MSCMoreOptionTableViewCell ()

@property (nonatomic, assign) MSCMoreOptionTableViewCellDelegateAbilities delegateHas;
@property (nonatomic, strong) UIButton *moreOptionButton;
@property (nonatomic, strong) UIScrollView *cellScrollView;

@end

@implementation MSCMoreOptionTableViewCell

////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
////////////////////////////////////////////////////////////////////////

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _moreOptionButton = nil;
        _cellScrollView = nil;

        [self setupMoreOption];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _moreOptionButton = nil;
        _cellScrollView = nil;

        [self setupMoreOption];
    }
    return self;
}

- (void)dealloc {
    [self.cellScrollView.layer removeObserver:self forKeyPath:@"sublayers" context:nil];
}

- (void)setDelegate:(id<MSCMoreOptionTableViewCellDelegate>)delegate {
    if (delegate != _delegate) {
        _delegate = delegate;
        MSCMoreOptionTableViewCellDelegateAbilities delegateAbilities = {};
        delegateAbilities.backgroundColorForDeleteConfirmationButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:)];
        delegateAbilities.backgroundColorForMoreOptionButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:backgroundColorForMoreOptionButtonForRowAtIndexPath:)];
        delegateAbilities.moreOptionButtonPressedInRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:moreOptionButtonPressedInRowAtIndexPath:)];
        delegateAbilities.titleColorForDeleteConfirmationButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:titleColorForDeleteConfirmationButtonForRowAtIndexPath:)];
        delegateAbilities.titleColorForMoreOptionButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:titleColorForMoreOptionButtonForRowAtIndexPath:)];
        delegateAbilities.titleForMoreOptionButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:titleForMoreOptionButtonForRowAtIndexPath:)];

        delegateAbilities.imageForDeleteConfirmationButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:imageForDeleteConfirmationButtonForRowAtIndexPath:)];
        delegateAbilities.imageForMoreOptionButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:imageForMoreOptionButtonForRowAtIndexPath:)];
        self.delegateHas = delegateAbilities;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject(NSKeyValueObserving)
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"sublayers"]) {
        /*
         * Using '==' instead of 'isEqual:' to compare the layer's delegate and the cell's contentScrollView
         * because it must be the same instance and not an equal one.
         */
        if ([object isKindOfClass:[CALayer class]] && ((CALayer *)object).delegate == self.cellScrollView) {
            BOOL moreOptionDelteButtonVisiblePrior = (self.moreOptionButton != nil);
            BOOL swipeToDeleteControlVisible = NO;
            for (CALayer *layer in [(CALayer *)object sublayers]) {
                /*
                 * Check if the view is the "swipe to delete" container view.
                 */
                NSString *name = NSStringFromClass([layer.delegate class]);
                if ([name hasPrefix:@"UI"] && [name hasSuffix:@"ConfirmationView"]) {
                    if (self.moreOptionButton) {
                        swipeToDeleteControlVisible = YES;
                    }
                    else {
                        UIView *deleteConfirmationView = layer.delegate;
                        UITableView *tableView = [self tableView];
                        NSIndexPath* indexPath = [tableView indexPathForCell:self];
                        UIButton *deleteConfirmationButton = [self deleteButtonFromDeleteConfirmationView:deleteConfirmationView];

                        UIColor *deleteButtonColor = (self.delegateHas.backgroundColorForDeleteConfirmationButtonForRowAtIndexPath ? [self.delegate tableView:tableView backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:[tableView indexPathForCell:self]] : nil );

                        if (deleteButtonColor) {
                            deleteConfirmationButton.backgroundColor = deleteButtonColor;
                        }

                        UIColor *deleteButtonTitleColor = (self.delegateHas.titleColorForDeleteConfirmationButtonForRowAtIndexPath ? [self.delegate tableView:tableView titleColorForDeleteConfirmationButtonForRowAtIndexPath:[tableView indexPathForCell:self]] : nil );

                        if (deleteButtonColor) {
                            deleteConfirmationButton.titleLabel.textColor = deleteButtonTitleColor;
                        }

                        UIImage* deleteImage = (self.delegateHas.imageForDeleteConfirmationButtonForRowAtIndexPath ? [self.delegate tableView:tableView imageForDeleteConfirmationButtonForRowAtIndexPath:indexPath] : nil);
                        [deleteConfirmationButton setImage:deleteImage forState:UIControlStateNormal];

                        NSString* title = (self.delegateHas.titleForMoreOptionButtonForRowAtIndexPath ? [self.delegate tableView:tableView titleForMoreOptionButtonForRowAtIndexPath:indexPath] : nil );
                        UIImage* image = (self.delegateHas.imageForMoreOptionButtonForRowAtIndexPath ? [self.delegate tableView:tableView imageForMoreOptionButtonForRowAtIndexPath:indexPath] : nil);

                        if (title != nil || image != nil)
                        {
                            self.moreOptionButton = [[UIButton alloc] initWithFrame:CGRectZero];
                            [self.moreOptionButton addTarget:self action:@selector(moreOptionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                            [self setMoreOptionButtonTitle:title image:image inDeleteConfirmationView:deleteConfirmationView];
                            // Set "More" button's numberOfLines to 0 to enable support for multiline titles.
                            self.moreOptionButton.titleLabel.numberOfLines = 0;

                            // Try to get "More" titleColor from delegate
                            UIColor *titleColor = (self.delegateHas.titleColorForMoreOptionButtonForRowAtIndexPath ? [self.delegate tableView:tableView titleColorForMoreOptionButtonForRowAtIndexPath:[tableView indexPathForCell:self]] : [UIColor whiteColor]);

                            [self.moreOptionButton setTitleColor:titleColor forState:UIControlStateNormal];

                            // Try to get "More" backgroundColor from delegate
                            UIColor *backgroundColor = (self.delegateHas.backgroundColorForMoreOptionButtonForRowAtIndexPath ? [self.delegate tableView:tableView backgroundColorForMoreOptionButtonForRowAtIndexPath:[tableView indexPathForCell:self]] : [UIColor lightGrayColor] );
                            [self.moreOptionButton setBackgroundColor:backgroundColor];

                            // Add the "More" button to the cell's view hierarchy
                            [deleteConfirmationView addSubview:self.moreOptionButton];
                        }

                        break;
                    }
                }
            }
            if (moreOptionDelteButtonVisiblePrior && !swipeToDeleteControlVisible) {
                self.moreOptionButton = nil;
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - private methods
////////////////////////////////////////////////////////////////////////

/*
 * Looks for a UIDeleteConfirmationButton in a given UIDeleteConfirmationView.
 * Returns nil if the button could not be found.
 */
- (UIButton *)deleteButtonFromDeleteConfirmationView:(UIView *)deleteConfirmationView {
    for (UIButton *deleteConfirmationButton in deleteConfirmationView.subviews) {
        NSString *name = NSStringFromClass([deleteConfirmationButton class]);
        if ([name hasPrefix:@"UI"] && [name rangeOfString:@"Delete"].length > 0 && [name hasSuffix:@"Button"]) {
            return deleteConfirmationButton;
        }
    }
    return nil;
}

- (void)moreOptionButtonPressed:(id)sender {
    if (self.delegateHas.moreOptionButtonPressedInRowAtIndexPath) {
        [self.delegate tableView:[self tableView] moreOptionButtonPressedInRowAtIndexPath:[[self tableView] indexPathForCell:self]];
    }
}

- (UITableView *)tableView {
    UIView *tableView = self.superview;
    while(tableView) {
        if(![tableView isKindOfClass:[UITableView class]]) {
            tableView = tableView.superview;
        }
        else {
            return (UITableView *)tableView;
        }
    }
    return nil;
}

- (void)setMoreOptionButtonTitle:(NSString *)title image:(UIImage*)image inDeleteConfirmationView:(UIView *)deleteConfirmationView {
    CGFloat priorMoreOptionButtonFrameWidth = self.moreOptionButton.frame.size.width;

    [self.moreOptionButton setTitle:title forState:UIControlStateNormal];
    [self.moreOptionButton setImage:image forState:UIControlStateNormal];
    [self.moreOptionButton sizeToFit];

    CGRect moreOptionButtonFrame = CGRectZero;
    moreOptionButtonFrame.size.width = self.moreOptionButton.frame.size.width + 30.f;
    /*
     * Look for the "Delete" button to apply it's height also to the "More" button.
     * If it can't be found there is a fallback to the deleteConfirmationView's height.
     */
    UIButton *deleteConfirmationButton = [self deleteButtonFromDeleteConfirmationView:deleteConfirmationView];
    if (deleteConfirmationButton) {
        moreOptionButtonFrame.size.height = deleteConfirmationButton.frame.size.height;
    }

    if (moreOptionButtonFrame.size.height == 0.f) {
        moreOptionButtonFrame.size.height = deleteConfirmationView.frame.size.height;
    }
    self.moreOptionButton.frame = moreOptionButtonFrame;

    CGRect rect = deleteConfirmationView.frame;
    rect.size.width = self.moreOptionButton.frame.origin.x + self.moreOptionButton.frame.size.width + (deleteConfirmationView.frame.size.width - priorMoreOptionButtonFrameWidth);
    rect.origin.x = deleteConfirmationView.superview.bounds.size.width - rect.size.width;
    deleteConfirmationView.frame = rect;
}

- (void)setupMoreOption {
    /*
     * Look for UITableViewCell's scrollView.
     * Any CALayer found here can only be generated by UITableViewCell's
     * 'initWithStyle:reuseIdentifier:', so there is no way adding custom
     * sublayers before. This means custom sublayers are no problem and
     * don't break MSCMoreOptionTableViewCell's functionality.
     */
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.delegate isKindOfClass:[UIScrollView class]]) {
            _cellScrollView = (UIScrollView *)layer.delegate;
            [_cellScrollView.layer addObserver:self forKeyPath:@"sublayers" options:NSKeyValueObservingOptionNew context:nil];
            break;
        }
    }
}

@end