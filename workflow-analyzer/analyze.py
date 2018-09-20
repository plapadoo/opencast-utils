#!/usr/bin/env python

from typing import List, Dict, cast
from pathlib import Path
import argparse
import re
import xml.etree.ElementTree as ET
from graphviz import Digraph

parser = argparse.ArgumentParser(description='Analyze Opencast workflows', )
parser.add_argument(
    '--visualize-tree',
    type=str,
    help='Visualize the dependencies that a workflow has on other workflows',
)

args = parser.parse_args()


class Operation:
    def __init__(
            self,
            opid: str,
            description: str,
            configurations: Dict[str, str],
    ) -> None:
        self.opid = opid
        self.configurations = configurations
        self.description = description


class Workflow:
    def __init__(
            self,
            wfid: str,
            title: str,
            operations: List[Operation],
            variables: List[str],
    ) -> None:
        self.operations = operations
        self.wfid = wfid
        self.title = title
        self.variables = variables


ocns = '{http://workflow.opencastproject.org}'


def parse_operation(o: ET.Element) -> Operation:
    configs_xml = o.find(ocns + 'configurations')
    configs: Dict[str, str] = {}
    if configs_xml is not None:
        for con in configs_xml.findall(ocns + 'configuration'):
            value = con.get('key')
            if value is not None:
                configs[value] = con.text if con.text is not None else ""
    return Operation(
        opid=o.get('id'),
        description=o.get('description'),
        configurations=configs,
    )


def parse_workflow_file(workflow_file: Path) -> Workflow:
    variables: List[str] = []
    with workflow_file.open() as wfile:
        content = wfile.read()
        for match in re.findall(re.compile(r'\${([^}]+)}'), content):
            variables.append(str(match))
    root = ET.parse(str(workflow_file)).getroot()
    operations = [
        parse_operation(o) for ops in root.findall(ocns + 'operations')
        for o in ops.findall(ocns + 'operation')
    ]
    wfid = root.find(ocns + 'id')
    title = root.find(ocns + 'title')
    return Workflow(
        operations=operations,
        wfid=cast(str, wfid.text if wfid is not None else ''),
        title=cast(str, title.text if title is not None else ''),
        variables=variables,
    )


def parse_workflow_tree(dirname: Path) -> Dict[str, Workflow]:
    result: Dict[str, Workflow] = {}
    for filename in dirname.iterdir():
        parsed = parse_workflow_file(filename)
        result[parsed.wfid] = parsed
    return result


def build_graph(t: Dict[str, Workflow]) -> Digraph:
    g = Digraph(engine='sfdp')
    g.attr('node', shape='none')
    g.attr(rankdir='LR')

    for k, v in t.items():
        label = '<<TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0"><TR><TD PORT="f0"><B>' + k + '</B></TD></TR>'
        for v in v.variables:
            label += '<TR><TD>' + v + '</TD></TR>'
        label += '</TABLE>>'
        g.node(k, label=label)

    for k, v in t.items():
        for op in v.operations:
            if op.opid == 'include':
                g.edge(
                    k,
                    op.configurations['workflow-id'],
                    label=op.description,
                    fontsize='8',
                    fontname='sans-serif')

    return g


if args.visualize_tree is not None:
    graph = Digraph(format='png')
    fn = Path(args.visualize_tree)
    parsed_tree = parse_workflow_tree(fn)
    build_graph(parsed_tree).render(filename='output')
    # root_name = os.path.basename(fn)
    # for op in parse_workflow_file(fn).operations:
    #     if op.opid == 'include':
    #         graph.edge('')
