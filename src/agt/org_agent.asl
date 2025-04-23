// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
    /* 1. Create & join workspace */
    .print("Initializing org ", OrgName);
    createWorkspace(lab_monitoring_wksp);
    joinWorkspace(lab_monitoring_wksp, WorkspaceId);
    .print("  → workspace created and joined: ", WorkspaceId);

    /* 2. Make & focus OrgBoard */
    makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgArgId);
    focus(OrgArgId);
    .print("  → OrgBoard ready: ", OrgArgId);

    /* 3. Create & focus GroupBoard */
    createGroup(GroupName, GroupName, GroupBoardId);
    focus(GroupBoardId);
    .print("  → GroupBoard ready for ‘", GroupName,"’: ", GroupBoardId);

    /* 4. Create & focus SchemeBoard */
    createScheme(SchemeName, SchemeName, SchemeBoardId);
    focus(SchemeBoardId);
    .print("  → SchemeBoard ready for ‘", SchemeName,"’: ", SchemeBoardId);

    /* 5. Notify other agents */
    .broadcast(tell, org_workspace_available(lab_monitoring_wksp, OrgName, GroupName, SchemeName));
    .print("  → broadcast: workspace ‘", OrgName,"’ is now available");

    /* 6. Wait for group formation */
    /* start our polling loop */
    !poll_group.

/* 
 * Every 15 seconds, as long as the group is not yet well-formed,
 * find each role R whose current players < min(R)
 * and invite any agent to adopt it
*/
/* 1) If still not well-formed, invite any role R with min=1 and no player yet */
@poll_group_not_yet_well_formed
+!poll_group : 
    not formationStatus(ok)[artifact_id(GroupBoardId)] <-
  ?role_cardinality(R, Min, _) ;
  ?not play(_, R, GroupBoardId);
  .print("Role ‘", R, "’ has no player – broadcasting invitation");
  .broadcast(tell, available_role(R, org_name(OrgName)));
  .wait(15000);
  !poll_group.

/* 2) Once well-formed, assign the scheme exactly once */
@poll_group_well_formed
+!poll_group : formationStatus(ok)[artifact_id(GroupBoardId)] 
              & sch_name(SchemeName)
<-
  .print("Group is now well-formed; assigning scheme '",SchemeName,"'");
  addScheme(SchemeName)[artifact_id(GroupBoardId)];
  .print("  → scheme assigned").  
/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }