//
//  TableViewCellWithSelection.swift
//  Flext
//
//  Created by Michael Camilleri on 31/8/20.
//  Copyright © 2021 Michael Camilleri. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0.

import UIKit

/**
 Represents a table view's cell with a selection.

 Flext allows the user to select the active processor. When listing processors
 in rows in a `UITableView`, we may wish to permit the user to tap the row to
 change the selection. Since UIKit does not offer a table view cell with a radio
 button control, this class provides that functionality.
 */
class TableViewCellWithSelection: UITableViewCell {

    // MARK: - Properties

    /// The symbol used for the selected state.
    let selectedCellImage = UIImage(systemName: "smallcircle.fill.circle.fill")

    /// The symbol used for the deselected state.
    var originalCellImage: UIImage!

    // MARK: - Nib Restoration

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: - Selection Toggling

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            originalCellImage = originalCellImage ?? imageView?.image
            imageView?.image = selectedCellImage
        } else {
            imageView?.image = originalCellImage ?? imageView?.image
        }
    }
}
