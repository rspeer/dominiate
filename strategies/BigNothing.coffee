# This is an implementation of the pure Big Money strategy, updated
# based on WanderingWinder's forum posts:
# http://forum.dominionstrategy.com/index.php?topic=625
{
  name: 'Big Nothing'
  requires: []
  gainPriority: (state, my) -> 
    if state.supply.Colony?
      [
      ]
    else
      [
      ]
}

