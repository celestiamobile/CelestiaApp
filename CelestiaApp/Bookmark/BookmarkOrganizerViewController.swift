//
//  BookmarkOrganizerViewController.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class BookmarkOrganizerViewController: NSViewController {
    private let pbIdentifier = "cc.meowssage.celestia.Bookmark"

    @IBOutlet private weak var outlineView: NSOutlineView!
    @IBOutlet private var treeController: NSTreeController!

    private var dragNodesArray: [NSTreeNode]?
    private var contents: NSMutableArray!

    var controller: BookmarkController!

    override func viewDidLoad() {
        super.viewDidLoad()

        outlineView.dataSource = self
        outlineView.registerForDraggedTypes([.init(rawValue: pbIdentifier)])
        contents = NSMutableArray(array: controller.storedBookmarks)
        treeController.content = contents

        let menu = NSMenu(title: "")
        let deleteItem = NSMenuItem(title: NSLocalizedString("Delete", comment: ""), action: #selector(performDelete), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        outlineView.menu = menu
        outlineView.target = self
        outlineView.doubleAction = #selector(performGoTo)
    }

    @objc private func performDelete() {
        let clickedRow = outlineView.clickedRow
        guard clickedRow >= 0 else { return }

        if let indexPath = (outlineView.item(atRow: clickedRow) as? NSTreeNode)?.indexPath {
            treeController.removeObject(atArrangedObjectIndexPath: indexPath)
        }
    }

    @objc private func performGoTo() {
        let clickedRow = outlineView.clickedRow
        guard clickedRow >= 0 else { return }

        if let item = (outlineView.item(atRow: clickedRow) as? NSTreeNode)?.representedObject as? BookmarkNode, !item.url.isEmpty {
            AppDelegate.shared.core.go(to: item.url)
        }
    }

    private func selectParentFromSelection() {
        if !self.treeController.selectedNodes.isEmpty {
            let firstSelectedNode = self.treeController.selectedNodes[0]
            if let parentNode = firstSelectedNode.parent {
                // select the parent
                let parentIndex = parentNode.indexPath
                self.treeController.setSelectionIndexPath(parentIndex)
            } else {
                // no parent exists (we are at the top of tree), so make no selection in our outline
                let selectionIndexPaths = self.treeController.selectionIndexPaths
                self.treeController.removeSelectionIndexPaths(selectionIndexPaths)
            }
        }
    }

    @IBAction func createFolder(_ sender: Any) {
        // NSTreeController inserts objects using NSIndexPath, so we need to calculate this
        var indexPath: IndexPath

        // if there is no selection, we will add a new group to the end of the contents array
        if self.treeController.selectedObjects.isEmpty {
            // there's no selection so add the folder to the top-level and at the end
            indexPath = IndexPath(index: self.contents.count)
        } else {
            // get the index of the currently selected node, then add the number its children to the path -
            // this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
            //
            indexPath = self.treeController.selectionIndexPath!
            if (self.treeController.selectedObjects[0] as! BookmarkNode).isLeaf {
                // user is trying to add a folder on a selected child,
                // so deselect child and select its parent for addition
                self.selectParentFromSelection()
            } else {
                indexPath.append((self.treeController.selectedObjects[0] as! BookmarkNode).children.count)
            }
        }

        let node = BookmarkNode(name: NSLocalizedString("Untitled", comment: ""), url: "", isFolder: true)

        // the user is adding a child node, tell the controller directly
        self.treeController.insert(node, atArrangedObjectIndexPath: indexPath)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        controller.storedBookmarks = contents as! [BookmarkNode]
        controller.buildBookmarkMenu()
    }
}

extension BookmarkOrganizerViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        pasteboard.declareTypes([.init(rawValue: pbIdentifier)], owner: self)
        dragNodesArray = items as? [NSTreeNode]
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {

        // no item to drop on
        guard let myItem = item else { return .generic }

        if index == -1 {
            // don't allow dropping on a child
            return NSDragOperation()
        } else if let nodes = dragNodesArray, nodes.contains(where: { (tree) -> Bool in
            let containerIndexPath = (myItem as AnyObject).indexPath!!
            return containerIndexPath.starts(with: tree.indexPath)
        }) {
            // don't allow dropping on itself or its child container
            return NSDragOperation()
        } else {
            // drop location is a container
            return .move
        }
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var result = false

        // find the index path to insert our dropped object(s)
        let indexPath: IndexPath
        if item != nil {
            // drop down inside the tree node:
            // feth the index path to insert our dropped node
            indexPath = (item! as AnyObject).indexPath!!.appending(index)
        } else {
            // drop at the top root level
            if index == -1 {    // drop area might be ambiguous (not at a particular location)
                indexPath = IndexPath(index: self.contents.count) // drop at the end of the top level
            } else {
                indexPath = IndexPath(index: index) // drop at a particular place at the top level
            }
        }

        let pboard = info.draggingPasteboard    // get the pasteboard

        // check the dragging type -
        if pboard.availableType(from: [.init(rawValue: pbIdentifier)]) != nil {
            // user is doing an intra-app drag within the outline view
            self.handleInternalDrops(pboard, withIndexPath: indexPath)
            result = true
        }
        return result
    }

    private func handleInternalDrops(_ pboard: NSPasteboard, withIndexPath indexPath: IndexPath) {
        // user is doing an intra app drag within the outline view:
        //
        let newNodes = self.dragNodesArray!

        // move the items to their new place
        self.treeController.move(self.dragNodesArray!, to: indexPath)

        // keep the moved nodes selected
        var indexPathList: [IndexPath] = []
        for node in newNodes {
            indexPathList.append(node.indexPath)
        }
        self.treeController.setSelectionIndexPaths(indexPathList)
    }

}
