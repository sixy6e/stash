#!/usr/bin/env python

import numpy

class tree(decision):
    """
    Base structure for creating a decision tree, similar to that found within ENVI.

    Ideas taken from http://cbio.ufs.ac.za/live_docs/nbn_tut/trees.html


    A sample method of creating a tree
    N1 = node('Node 1', node_type='Decision', expression='b1 <= -0.01',
              children=[node('Node 2', node_type='Decision', expression='b2 <= 2083.5', parent_name='Node 1', parent_decision=True,
              children=[node('Node 3', node_type='Result', parent_name='Node 2', parent_decision=False, class_value=1),
                        node('Node 4', node_type='Decision', expression='b3 <= 323.5', parent_name='Node 2', parent_decision=True,
              children=[node('Node 5', node_type='Result', parent_name='Node 4', parent_decision=True, class_value=2)]
                            )
                            )
             )
    """
    def __init__(self, name, node_type, parent_name, parent_decision, children, expression, class_value):
        """
        Node types can be either a decision or a result.
        Expression of type string???? How then to deal with actual evaluation.
        """
        self.name            = name
        self.type            = type
        self.parent_name     = parent_name
        self.parent_decision = parent_decision
        self.expression      = expression

    def add_node(self, node):
        """
        A method of adding a new node to a parent.
        """
        if not node.parent_name:
            return None # Need a parent to add a new node???
        else:
            

